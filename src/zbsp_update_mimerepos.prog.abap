*&---------------------------------------------------------------------*
*& Report  BSP_UPDATE_MIMEREPOS
*&
*&---------------------------------------------------------------------*
*&
*& Comparison of MIME Repository with frontend data
*&
*&---------------------------------------------------------------------*

REPORT  zbsp_update_mimerepos LINE-SIZE 316.

INCLUDE <icon>.

CONSTANTS: co_max_length TYPE i VALUE 256.
CONSTANTS: co_loio_file  TYPE string VALUE 'sap_loios.txt'.

DATA: l_filename       TYPE string.
DATA: l_loiofile       TYPE string.
DATA: itab_mr_path     TYPE string_table.
DATA: wa_mr_path       TYPE string.
DATA: itab_mr_parts    TYPE string_table.
DATA: wa_mr_parts      TYPE string.
DATA: xchar(1024)      TYPE x.
DATA: itab_files       LIKE TABLE OF xchar.
DATA: wa_ascii(302)    TYPE c.
DATA: itab_ascii       LIKE TABLE OF wa_ascii.
DATA: wa_files         LIKE LINE OF itab_files.
DATA: l_content        TYPE xstring.
DATA: l_current        TYPE xstring.
DATA: wa_file_table    TYPE file_info.
DATA: wa_file_table2   TYPE file_info.
DATA: itab_dir_table   TYPE STANDARD TABLE OF file_info.
DATA: itab_dir_table2  TYPE STANDARD TABLE OF file_info.
DATA: itab_file_table  TYPE STANDARD TABLE OF file_info.
DATA: itab_file_table2 TYPE STANDARD TABLE OF file_info.
DATA: BEGIN OF wa_file_loio,
        name(256)    TYPE c,
        loio         TYPE skwf_io,
        is_folder(1),
      END OF wa_file_loio.
DATA: itab_loio LIKE TABLE OF wa_file_loio.
DATA: l_directory      TYPE string.
DATA: l_url            TYPE string.
DATA: l_loio           TYPE skwf_io.
DATA: o_mr_api         TYPE REF TO if_mr_api.
DATA: is_folder TYPE boole_d.
DATA: l_filelength   TYPE i, x TYPE i, y TYPE i, l_count TYPE i,
      file_counter   TYPE i, folder_counter TYPE i.

**********************************************************************
**********************************************************************

SELECTION-SCREEN BEGIN OF BLOCK mpath WITH FRAME TITLE TEXT-001.
PARAMETERS: mimepath(255) TYPE c LOWER CASE
* --- default mimepath for 6.40!
*             DEFAULT '/SAP/PUBLIC/BC/UR/Design2002/'.
            DEFAULT '/SAP/BC/BSP/SAP/myBSPapplication/'.
SELECTION-SCREEN END OF BLOCK mpath.

SELECTION-SCREEN BEGIN OF BLOCK imex WITH FRAME TITLE TEXT-012.
PARAMETERS: export RADIOBUTTON GROUP imex.
SELECTION-SCREEN BEGIN OF LINE.
SELECTION-SCREEN POSITION 1.
PARAMETERS: import RADIOBUTTON GROUP imex.
SELECTION-SCREEN: COMMENT 3(18) TEXT-037.
SELECTION-SCREEN POSITION 22.


PARAMETERS: ovwrloio AS CHECKBOX DEFAULT ''.
SELECTION-SCREEN: COMMENT 25(30) TEXT-038.
SELECTION-SCREEN END OF LINE.
SELECTION-SCREEN END OF BLOCK imex.

SELECTION-SCREEN BEGIN OF BLOCK dept WITH FRAME TITLE TEXT-015.
PARAMETERS: deeppath RADIOBUTTON GROUP dept.
PARAMETERS: flatpath RADIOBUTTON GROUP dept.
PARAMETERS: onefile  RADIOBUTTON GROUP dept.
SELECTION-SCREEN END   OF BLOCK dept.

PARAMETERS: _rootdir TYPE string LOWER CASE OBLIGATORY.
SELECT-OPTIONS:
            _skip_rn FOR wa_file_table-filename LOWER CASE OBLIGATORY.

*  SELECTION-SCREEN BEGIN OF BLOCK loio WITH FRAME TITLE text-036.
*  PARAMETERS: withloio AS CHECKBOX DEFAULT 'X'.
*  SELECTION-SCREEN END   OF BLOCK loio.
**********************************************************************
**********************************************************************


INITIALIZATION.
  _skip_rn[] = VALUE #( sign = 'I' option = 'CP' ( low = 'node_modules*' )
                                                 ( low = 'dist*' ) ).

START-OF-SELECTION.


  DATA: withloio TYPE c VALUE space.

* --- MIMEPATH must end with /
  CONDENSE mimepath.
  x = strlen( mimepath ) - 1.
  IF mimepath+x(1) NE '/'.
    CONCATENATE mimepath '/' INTO mimepath.
  ENDIF.

  IF mimepath(4) NE '/SAP'.
    WRITE: /(6) icon_red_light AS ICON, (65) TEXT-041.
*     Verwendung dieses Programmes nur bzgl. Wurzelelement /SAP möglich!
    EXIT.
  ENDIF.

  DATA: l_title TYPE string.
  DATA: l_file_table TYPE filetable.
  DATA: wa_single_file TYPE file_table.
  DATA: l_rc TYPE i.
  IF onefile = 'X' AND import = 'X'.
* --- select a single file
    CALL METHOD cl_gui_frontend_services=>file_open_dialog
      EXPORTING
        window_title            = l_title
*       DEFAULT_EXTENSION       =
*       DEFAULT_FILENAME        =
*       FILE_FILTER             =
*       WITH_ENCODING           =
        initial_directory       = 'C:\'
        multiselection          = ''
      CHANGING
        file_table              = l_file_table
        rc                      = l_rc
*       USER_ACTION             =
*       FILE_ENCODING           =
      EXCEPTIONS
        file_open_dialog_failed = 1
        cntl_error              = 2
        error_no_gui            = 3
        not_supported_by_gui    = 4
        OTHERS                  = 5.
    IF sy-subrc <> 0.
      WRITE: /(6) icon_red_light AS ICON, (55) TEXT-016.
*     Datei konnte nicht ermittelt werden!
      EXIT.
    ENDIF.
    IF l_rc = 1.
      READ TABLE l_file_table INTO wa_single_file INDEX 1 TRANSPORTING filename.
      wa_file_table-filename = wa_single_file-filename.
      APPEND wa_file_table TO itab_file_table.
    ENDIF.
  ELSE.
    l_title = TEXT-017.

    IF _rootdir IS INITIAL.
      WRITE: /(6) icon_red_light AS ICON, (55) TEXT-003.
*     Das Wurzelverzeichnis konnte nicht ermittelt werden!
      EXIT.
    ENDIF.
  ENDIF.
* --- #####################
* --- #     IMPORT        #
* --- #####################
  IF import = 'X'.
    PERFORM do_import.
  ELSEIF export = 'X'.

    PERFORM do_export.

  ENDIF.  "import/export

  IF NOT o_mr_api IS INITIAL.
    FREE o_mr_api.
  ENDIF.

FORM do_import.
  IF NOT onefile = 'X'.
    IF deeppath = 'X'.
* --- collect subdirectories of root directory
* --- (-> top level)
      CALL METHOD cl_gui_frontend_services=>directory_list_files
        EXPORTING
          directory                   = _rootdir
          directories_only            = 'X'
        CHANGING
          file_table                  = itab_dir_table
          count                       = l_count
        EXCEPTIONS
          cntl_error                  = 1
          directory_list_files_failed = 2
          wrong_parameter             = 3
          error_no_gui                = 4
          not_supported_by_gui        = 5
          OTHERS                      = 6.

      IF sy-subrc <> 0.
        WRITE: /(6) icon_red_light AS ICON, (55) TEXT-004.
*         Die Verzeichnisliste konnte nicht erstellt werden!
        EXIT.
      ENDIF.
      DELETE itab_dir_table WHERE filename IN _skip_rn[].


      l_directory = _rootdir.

* --- collect all subdirectories beginning with second layer
      LOOP AT itab_dir_table INTO wa_file_table.

        REFRESH itab_dir_table2.
        CONCATENATE _rootdir '\' wa_file_table-filename INTO l_directory.

        CALL METHOD cl_gui_frontend_services=>directory_list_files
          EXPORTING
            directory                   = l_directory
            directories_only            = 'X'
          CHANGING
            file_table                  = itab_dir_table2
            count                       = l_count
          EXCEPTIONS
            cntl_error                  = 1
            directory_list_files_failed = 2
            wrong_parameter             = 3
            error_no_gui                = 4
            not_supported_by_gui        = 5
            OTHERS                      = 6.

        IF sy-subrc <> 0.
          WRITE: /(6) icon_red_light AS ICON, (55) TEXT-004.
*           Die Verzeichnisliste konnte nicht erstellt werden!
          EXIT.
        ENDIF.

* --- gradual collection of all directories in itab_dir_table
        LOOP AT itab_dir_table2 INTO wa_file_table2.
          CONCATENATE wa_file_table-filename '\' wa_file_table2-filename INTO wa_file_table2-filename.
          APPEND wa_file_table2 TO itab_dir_table.
        ENDLOOP.

      ENDLOOP.  "itab_dir_table

    ENDIF. "deeppath



* --- don't forget the files of root directory
* --- -> initial filename assures that these files are included
    APPEND INITIAL LINE TO itab_dir_table.

* --- now collect files of all directories
    LOOP AT itab_dir_table INTO wa_file_table.

      REFRESH itab_file_table2.
      CONCATENATE _rootdir '\' wa_file_table-filename INTO l_directory.

* --- get file list
      CALL METHOD cl_gui_frontend_services=>directory_list_files
        EXPORTING
          directory                   = l_directory
          files_only                  = 'X'
        CHANGING
          file_table                  = itab_file_table2
          count                       = l_count
        EXCEPTIONS
          cntl_error                  = 1
          directory_list_files_failed = 2
          wrong_parameter             = 3
          error_no_gui                = 4
          not_supported_by_gui        = 5
          OTHERS                      = 6.
      IF sy-subrc <> 0.
        WRITE: /(6) icon_red_light AS ICON, (55) TEXT-005.
*         Die Dateiliste konnte nicht erstellt werden!
        EXIT.
      ENDIF.

      LOOP AT itab_file_table2 INTO wa_file_table2.
* --- root directory: avert leading '\'
        IF NOT wa_file_table-filename IS INITIAL.
          CONCATENATE wa_file_table-filename '\' wa_file_table2-filename INTO wa_file_table2-filename.
        ENDIF.
* --- LOIO information must not be uploaded
        IF NOT wa_file_table2-filename EQ co_loio_file.
          APPEND wa_file_table2 TO itab_file_table.
        ENDIF.
      ENDLOOP.

    ENDLOOP.  "itab_dir_table
  ENDIF.  "onefile = 'X'

  IF o_mr_api IS INITIAL.
    o_mr_api = cl_mime_repository_api=>if_mr_api~get_api( ).
  ENDIF.

  IF withloio = 'X'.
    CONCATENATE _rootdir '\' co_loio_file INTO l_loiofile.

    CALL METHOD cl_gui_frontend_services=>gui_upload
      EXPORTING
        filename                = l_loiofile
        filetype                = 'ASC'
        has_field_separator     = 'X'
      IMPORTING
        filelength              = l_filelength
      CHANGING
        data_tab                = itab_loio
      EXCEPTIONS
        file_open_error         = 1
        file_read_error         = 2
        no_batch                = 3
        gui_refuse_filetransfer = 4
        invalid_type            = 5
        no_authority            = 6
        unknown_error           = 7
        bad_data_format         = 8
        header_not_allowed      = 9
        separator_not_allowed   = 10
        header_too_long         = 11
        unknown_dp_error        = 12
        access_denied           = 13
        dp_out_of_memory        = 14
        disk_full               = 15
        dp_timeout              = 16
        not_supported_by_gui    = 17
        error_no_gui            = 18
        OTHERS                  = 19.
    IF sy-subrc <> 0.
      IF sy-subrc = 1.
        WRITE: /(6) icon_red_light AS ICON, (55) TEXT-029, l_loiofile.
*         Datei mit LOIO-Informationen ist nicht vorhanden
      ELSE.
        WRITE: /(6) icon_red_light AS ICON, (55) TEXT-030, l_loiofile.
*         Fehler beim Lesen der LOIO-informationen aus Datei
      ENDIF.
      EXIT.
    ENDIF.

  ENDIF.  "withloio

* --- now compare the LOIOs of local folders with MR information
* --- + if the folder is missing, we will create with given LOIO
* --- + it folder is present, but LOIOs differ, we will only write a message
  LOOP AT itab_loio INTO wa_file_loio WHERE is_folder = 'X'.

    l_filelength = strlen( _rootdir ).
*        wa_file_loio-name = wa_file_loio-name+l_filelength.
    SHIFT wa_file_loio-name BY l_filelength PLACES.
    IF wa_file_loio-name(1) = '\'.
      SHIFT wa_file_loio-name BY 1 PLACES.
    ENDIF.
    CONCATENATE mimepath wa_file_loio-name INTO l_url.
* --- to be consistent with windows pathes
    TRANSLATE l_url USING '\/'.

    CLEAR: is_folder.

    CALL METHOD o_mr_api->get
      EXPORTING
        i_url              = l_url
      IMPORTING
        e_is_folder        = is_folder
        e_content          = l_current
        e_loio             = l_loio
      EXCEPTIONS
        parameter_missing  = 1
        error_occured      = 2
        not_found          = 3
        permission_failure = 4
        OTHERS             = 5.

    IF sy-subrc = 3.
* --- MR does not contain this folder -> create it with given LOIO
      WRITE: /(6) icon_folder AS ICON, (55) TEXT-018, l_url.
*       Ordner existiert nicht
      CALL METHOD o_mr_api->create_folder
        EXPORTING
          i_url                     = l_url
          i_suppress_package_dialog = 'X'
          i_folder_loio             = wa_file_loio-loio
*         IMPORTING
*         E_FOLDER_IO               =
        EXCEPTIONS
          parameter_missing         = 1
          error_occured             = 2
          cancelled                 = 3
          permission_failure        = 4
          folder_exists             = 5
          OTHERS                    = 6.

      IF sy-subrc <> 0.
        CASE sy-subrc.
          WHEN 4.
            WRITE: /(6) icon_red_light AS ICON, (55) TEXT-009, l_url.
*                     Keine Schreibberechtigung an Mime-Objekt
          WHEN OTHERS.
            WRITE: /(6) icon_red_light AS ICON, (55) TEXT-010, l_url.
*                     Fehler beim Anlegen des Mime-Objektes
        ENDCASE.
      ELSE.
        WRITE: /(6) icon_green_light AS ICON, (55) TEXT-032, l_url.
*         Ordner wurde neu angelegt
        folder_counter = folder_counter + 1.
      ENDIF.
    ELSE.
      IF l_loio NE wa_file_loio-loio AND withloio = 'X'.
        WRITE: /(6) icon_yellow_light AS ICON, (55) TEXT-019, l_url.
*         LOIOs unterschiedlich
      ENDIF.
    ENDIF.
  ENDLOOP.

* --- handle each file separately
  LOOP AT itab_file_table INTO wa_file_table.

    IF NOT onefile = 'X'.
* --- method directory_browse(^) exports rootdir without ending \
      CONCATENATE _rootdir '\' wa_file_table-filename INTO l_filename.
    ELSE.
      l_filename = wa_file_table-filename.
    ENDIF.

    CALL METHOD cl_gui_frontend_services=>gui_upload
      EXPORTING
        filename                = l_filename
        filetype                = 'BIN'
        read_by_line            = 'X'
      IMPORTING
        filelength              = l_filelength
      CHANGING
        data_tab                = itab_files
      EXCEPTIONS
        file_open_error         = 1
        file_read_error         = 2
        no_batch                = 3
        gui_refuse_filetransfer = 4
        invalid_type            = 5
        no_authority            = 6
        unknown_error           = 7
        bad_data_format         = 8
        header_not_allowed      = 9
        separator_not_allowed   = 10
        header_too_long         = 11
        unknown_dp_error        = 12
        access_denied           = 13
        dp_out_of_memory        = 14
        disk_full               = 15
        dp_timeout              = 16
        not_supported_by_gui    = 17
        error_no_gui            = 18
        OTHERS                  = 19.

    IF sy-subrc <> 0.
      WRITE: /(6) icon_red_light AS ICON, (55) TEXT-006, l_filename.
*       Fehler beim Upload der Datei!
      CONTINUE.
    ENDIF.

    CLEAR: l_content.

* --- we need the file content as xstring
    LOOP AT itab_files INTO wa_files.
      CONCATENATE l_content wa_files INTO l_content IN BYTE MODE.
    ENDLOOP.

* --- cut according to filelength
    l_content = l_content(l_filelength).

    CLEAR: x, y, l_url.

    IF l_url IS INITIAL.
      IF onefile = 'X'.
        CLEAR: x, y.
        DO.
          FIND '\' IN wa_file_table-filename+x MATCH OFFSET y.
          IF sy-subrc = 0.
            x = x + y + 1.
          ELSE.
            EXIT.
          ENDIF.
        ENDDO.
        CONCATENATE mimepath wa_file_table-filename+x INTO l_url.
        CLEAR: x, y.
      ELSE.
        CONCATENATE mimepath wa_file_table-filename INTO l_url.
      ENDIF.
    ENDIF.

* --- to be consistent with windows pathes
    TRANSLATE l_url USING '\/'.

* --- now compare the LOIOs of local files with MR information
* --- + if file is missing, we will create it with given LOIO
* --- + if file is present, but LOIOs differ:
* ---   ++ if checkbox ovwrloio is checked, we will delete MR file
* ---   ++ otherwise we will only write a message
    IF NOT itab_loio IS INITIAL.
*        DATA: l_url_folder LIKE l_url.
*        LOOP AT itab_loio INTO wa_file_loio WHERE is_folder IS INITIAL.
      DATA: abs_name LIKE wa_file_table-filename.
      CONCATENATE _rootdir '\' wa_file_table-filename INTO abs_name.
      READ TABLE itab_loio WITH KEY name = abs_name INTO wa_file_loio.
      IF sy-subrc <> 0.
        ULINE.
        FORMAT COLOR COL_NEGATIVE ON.
        WRITE: /(6) icon_loio_class AS ICON, (255) TEXT-033.
*         LOIO zu File konnte nicht ermttelt werden
        WRITE: /(6) icon_red_light AS ICON, (255) TEXT-034.
        WRITE: /(6) icon_red_light AS ICON, (255) abs_name.
*         Datei wird nicht angelegt!
        FORMAT COLOR COL_NEGATIVE OFF.
        ULINE.
        CONTINUE.
      ENDIF.
*          CONCATENATE mimepath wa_file_loio-name INTO l_url.
      CLEAR: is_folder.

* --- to be consistent with windows pathes
      TRANSLATE l_url USING '\/'.

      CALL METHOD o_mr_api->get
        EXPORTING
          i_url              = l_url
        IMPORTING
          e_is_folder        = is_folder
          e_content          = l_current
          e_loio             = l_loio
        EXCEPTIONS
          parameter_missing  = 1
          error_occured      = 2
          not_found          = 3
          permission_failure = 4
          OTHERS             = 5.
*
      IF sy-subrc <> 0.
        CASE sy-subrc.
          WHEN 3.              "* --- mime not found -> go on...
            CLEAR l_current.
          WHEN 4.
            WRITE: /(6) icon_red_light AS ICON, (55) TEXT-007, l_url.
*             Keine Leseberechtigung an Mime-Objekt
            CONTINUE.
          WHEN OTHERS.
            WRITE: /(6) icon_red_light AS ICON, (55) TEXT-008, l_url.
*             Fehler beim Lesen des Mime-Objektes
            CONTINUE.
        ENDCASE.
      ELSE.
        IF wa_file_loio-loio NE l_loio AND withloio = 'X'.
          WRITE: /(6) icon_yellow_light AS ICON, (55) TEXT-019, l_url.
*           LOIOs unterschiedlich
          IF ovwrloio EQ 'X'.
* --- delete MR file, if LOIOs differ
            CALL METHOD o_mr_api->delete
              EXPORTING
                i_url              = l_url
                i_delete_children  = ''
                i_check_authority  = 'X'
*               I_CORR_NUMBER      =
              EXCEPTIONS
                parameter_missing  = 1
                error_occured      = 2
                cancelled          = 3
                permission_failure = 4
                not_found          = 5
                OTHERS             = 6.

            IF sy-subrc <> 0.
              CASE sy-subrc.
                WHEN 4.
                  WRITE: /(6) icon_red_light AS ICON, (55) TEXT-023, l_url.
*                   Keine Berechtigung zum Löschen der Datei
                  CONTINUE.
                WHEN OTHERS.
                  WRITE: /(6) icon_red_light AS ICON, (55) TEXT-022, l_url.
*                   Fehler beim Löschen der Datei
                  CONTINUE.
              ENDCASE.
            ELSE.
              WRITE: /(6) icon_loio_class AS ICON, (55) TEXT-024, l_url.
*               Datei wird neu angelegt (LOIO-Abgleich)
              CLEAR l_current.
            ENDIF.

          ENDIF.  "ovwrloio
        ENDIF.  "wa_file_loio-loio NE l_loio and withloio = 'X
      ENDIF.  "sy-subrc
    ENDIF.  "itab_loio initial

* --- new
    IF withloio IS INITIAL.
* --- to be consistent with windows pathes
      TRANSLATE l_url USING '\/'.

      CALL METHOD o_mr_api->get
        EXPORTING
          i_url              = l_url
        IMPORTING
          e_is_folder        = is_folder
          e_content          = l_current
          e_loio             = l_loio
        EXCEPTIONS
          parameter_missing  = 1
          error_occured      = 2
          not_found          = 3
          permission_failure = 4
          OTHERS             = 5.
*
      IF sy-subrc <> 0.
        CASE sy-subrc.
          WHEN 3.              "* --- mime not found -> go on...
            CLEAR l_current.
          WHEN 4.
            WRITE: /(6) icon_red_light AS ICON, (55) TEXT-007, l_url.
*             Keine Leseberechtigung an Mime-Objekt
            CONTINUE.
          WHEN OTHERS.
            WRITE: /(6) icon_red_light AS ICON, (55) TEXT-008, l_url.
*             Fehler beim Lesen des Mime-Objektes
            CONTINUE.
        ENDCASE.
      ENDIF.
    ENDIF.
* --- end new

* --- check, if this is a css-file
* --- css -> convert to ascii, exclude timestamp and compare ascii
    DATA: l_oldascii   TYPE string.
    DATA: l_newascii   TYPE string.
    DATA: conv         TYPE REF TO cl_abap_conv_in_ce.
    DATA: length       TYPE i.
    DATA: new_offset TYPE i, old_offset TYPE i.

    CLEAR: new_offset, old_offset, l_newascii, l_oldascii.

    length = strlen( l_url ) - 4.
    IF length > 0 AND l_url+length CS '.css'.

* --- NEW: exclude timestamp (17B) and compare xstring...
      IF xstrlen( l_content ) > 17 AND xstrlen( l_current ) > 17.
        IF l_current+17 = l_content+17.
          CONTINUE.
        ENDIF.
      ENDIF.
*        conv = cl_abap_conv_in_ce=>create( input = l_content ).
*        conv->read( IMPORTING data = l_newascii len = length ).
*
*        IF NOT l_current IS INITIAL.
*          conv = cl_abap_conv_in_ce=>create( input = l_current ).
*          conv->read( IMPORTING data = l_oldascii len = length ).
*        ENDIF.
*
** --- identify timestamp and the corresponding offset
*        IF STRLEN( l_newascii ) > 24 AND l_newascii(2) = '/*' AND l_newascii+2(22) CS '*/'.
*          new_offset = sy-fdpos + 4.
*        ENDIF.
*        IF STRLEN( l_oldascii ) > 24 AND l_oldascii(2) = '/*' AND l_oldascii+2(22) CS '*/'.
*          old_offset = sy-fdpos + 4.
*        ENDIF.
*
** --- compare ascii
*        IF l_oldascii+old_offset = l_newascii+new_offset.
*          CONTINUE.
*        ENDIF.
*
    ELSE.
* --- compare binary
      IF l_current = l_content.
        CONTINUE.
      ENDIF.
    ENDIF.

* --- update only if content has changed
* --- if no LOIO was included, the put method will
* --- create a new one
    CALL METHOD o_mr_api->put
      EXPORTING
        i_url                     = l_url
        i_content                 = l_content
        i_suppress_package_dialog = 'X'
        i_new_loio                = wa_file_loio-loio
      EXCEPTIONS
        parameter_missing         = 1
        error_occured             = 2
        cancelled                 = 3
        permission_failure        = 4
        data_inconsistency        = 5
        OTHERS                    = 6.

    IF sy-subrc <> 0.
      CASE sy-subrc.
        WHEN 4.
          WRITE: /(6) icon_red_light AS ICON, (55) TEXT-009, l_url.
*           Keine Schreibberechtigung an Mime-Objekt
        WHEN OTHERS.
          WRITE: /(6) icon_red_light AS ICON, (55) TEXT-010, l_url.
*           Fehler beim Anlegen des Mime-Objektes
      ENDCASE.
    ELSE.
      WRITE: /(6) icon_green_light AS ICON, (55) TEXT-025, l_url.
*       MIME-Objekt wurde neu angelegt
      file_counter = file_counter + 1.
    ENDIF.

  ENDLOOP.

* --- Cache invalidieren
  CALL FUNCTION 'ICM_CACHE_INVALIDATE_ALL'
    EXPORTING
      global              = 1
    EXCEPTIONS
      icm_op_failed       = 1
      icm_get_serv_failed = 2
      icm_no_http_service = 3
      OTHERS              = 4.

  IF sy-subrc <> 0.
    ULINE.
    WRITE: /(6) icon_yellow_light AS ICON, (55) TEXT-040, l_url.
*     Fehler beim Invalidieren des ICM Caches
  ENDIF.

  ULINE.
  WRITE: /(6) icon_folder AS ICON, (55) TEXT-027, folder_counter.
*   Anzahl neu angelegter Ordner
  WRITE: /(6) icon_write_file AS ICON, (55) TEXT-026, file_counter.
*   Anzahl neu angelegter Dateien

ENDFORM.

FORM do_export.
  CALL METHOD cl_gui_frontend_services=>directory_list_files
    EXPORTING
      directory                   = _rootdir
      directories_only            = ''
    CHANGING
      file_table                  = itab_dir_table
      count                       = l_count
    EXCEPTIONS
      cntl_error                  = 1
      directory_list_files_failed = 2
      wrong_parameter             = 3
      error_no_gui                = 4
      not_supported_by_gui        = 5
      OTHERS                      = 6.

  IF sy-subrc <> 0.
    WRITE: /(6) icon_red_light AS ICON, (55) TEXT-004.
*     Die Verzeichnisliste konnte nicht erstellt werden!
    EXIT.
  ENDIF.
  IF l_count <> 0.
    WRITE: /(6) icon_red_light AS ICON, (55) TEXT-031, _rootdir.
*     Verzeichnis ist nicht leer
    EXIT.
  ENDIF.

  CONCATENATE _rootdir '\' INTO _rootdir.
  CLEAR itab_ascii[].

  IF o_mr_api IS INITIAL.
    o_mr_api = cl_mime_repository_api=>if_mr_api~get_api( ).
  ENDIF.

* --- check if mimepath is a single file
  CALL METHOD o_mr_api->get
    EXPORTING
      i_url              = mimepath
      i_check_authority  = 'X'
    IMPORTING
      e_is_folder        = is_folder
      e_content          = l_current
      e_loio             = l_loio
    EXCEPTIONS
      parameter_missing  = 1
      error_occured      = 2
      not_found          = 3
      permission_failure = 4
      OTHERS             = 5.

  IF sy-subrc <> 0.
    CASE sy-subrc.
      WHEN 4.
        WRITE: /(6) icon_red_light AS ICON, (55) TEXT-013, mimepath.
*         Keine Leseberechtigung an Mime Repository!
      WHEN OTHERS.
        WRITE: /(6) icon_red_light AS ICON, (55) TEXT-014, mimepath.
*         Das MIME Repository konnte nicht gelesen werden!
    ENDCASE.
  ENDIF.

  DATA: single_file(1) VALUE ''.
  IF is_folder NE 'X'.
* --- export a single file
    single_file = 'X'.
    l_filelength = strlen( mimepath ) - 1.
    IF mimepath+l_filelength = '/'.
      wa_mr_path = mimepath(l_filelength).
    ELSE.
      wa_mr_path = mimepath.
    ENDIF.
    APPEND wa_mr_path TO itab_mr_path.
    CLEAR: x, y.
    DO.
      FIND '/' IN wa_mr_path+x MATCH OFFSET y.
      IF sy-subrc = 0.
        x = x + y + 1.
      ELSE.
        EXIT.
      ENDIF.
    ENDDO.
    mimepath = wa_mr_path(x).
    CLEAR: x, y.
  ELSE.
    IF onefile = 'X'.
      WRITE: /(6) icon_red_light AS ICON, (55) TEXT-039, mimepath.
*       Keine Leseberechtigung an Mime Repository!
      EXIT.
    ENDIF.
    CALL METHOD o_mr_api->file_list
      EXPORTING
        i_url              = mimepath
        i_recursive_call   = deeppath
        i_check_authority  = 'X'
      IMPORTING
        e_files            = itab_mr_path
      EXCEPTIONS
        parameter_missing  = 1
        error_occured      = 2
        not_found          = 3
        permission_failure = 4
        is_not_folder      = 5
        OTHERS             = 6.

    IF sy-subrc <> 0.
      CASE sy-subrc.
        WHEN 4.
          WRITE: /(6) icon_red_light AS ICON, (55) TEXT-013, mimepath.
*           Keine Leseberechtigung an Mime Repository!
        WHEN OTHERS.
          WRITE: /(6) icon_red_light AS ICON, (55) TEXT-014, mimepath.
*           Das MIME Repository konnte nicht gelesen werden!
      ENDCASE.
    ENDIF.

  ENDIF.

  CLEAR: wa_mr_path.
  LOOP AT itab_mr_path INTO wa_mr_path.

    IF withloio = 'X'.
* --- changes regarding folder LOIOs
      DATA: l_mime_length TYPE i.
      DATA: l_mr_path  TYPE string.
      l_url         = mimepath.
      l_mime_length = strlen( mimepath ).
      l_mr_path     = wa_mr_path+l_mime_length.
* --- split in order to analyze the folders
      SPLIT l_mr_path AT '/' INTO TABLE itab_mr_parts.

      LOOP AT itab_mr_parts INTO wa_mr_parts.

        CLEAR: is_folder, l_current, l_loio.
        IF single_file = 'X'.
          CONCATENATE l_url wa_mr_parts INTO l_url.
        ELSE.
          CONCATENATE l_url wa_mr_parts '/' INTO l_url.
        ENDIF.

        CALL METHOD o_mr_api->get
          EXPORTING
            i_url              = l_url
            i_check_authority  = 'X'
          IMPORTING
            e_is_folder        = is_folder
            e_content          = l_current
            e_loio             = l_loio
          EXCEPTIONS
            parameter_missing  = 1
            error_occured      = 2
            not_found          = 3
            permission_failure = 4
            OTHERS             = 5.

        IF sy-subrc <> 0.
          CASE sy-subrc.
            WHEN 3.              "* --- mime not found -> go on...
              CLEAR l_current.
              EXIT.
            WHEN 4.
              WRITE: /(6) icon_red_light AS ICON, (55) TEXT-007, l_url.
*               Keine Leseberechtigung an Mime-Objekt
              EXIT.
            WHEN OTHERS.
              WRITE: /(6) icon_red_light AS ICON, (55) TEXT-008, l_url.
*               Fehler beim Lesen des Mime-Objektes
              EXIT.
          ENDCASE.
        ENDIF.

* --- Now collect information about LOIOs in itab
* --- data separated with tabulator
        IF is_folder = 'X'.
          CONCATENATE l_url l_loio 'X' INTO wa_ascii SEPARATED BY cl_abap_char_utilities=>horizontal_tab.
        ELSE.
          DATA: url_len TYPE i.
          url_len = strlen( l_url ) - 1.
          IF l_url+url_len = '/'.
            l_url = l_url(url_len).
          ENDIF.
          CONCATENATE l_url l_loio INTO wa_ascii SEPARATED BY cl_abap_char_utilities=>horizontal_tab.
        ENDIF.

        REPLACE mimepath IN wa_ascii WITH _rootdir IGNORING CASE.
* --- to be consistent with windows pathes
        TRANSLATE wa_ascii USING '/\'.
* --- is there already a folder LOIO?
        READ TABLE itab_ascii WITH KEY wa_ascii TRANSPORTING NO FIELDS.
        IF sy-subrc NE 0.
          APPEND wa_ascii TO itab_ascii.
        ENDIF.

      ENDLOOP.
    ENDIF.                  "withloio

    l_url = wa_mr_path.

    CALL METHOD o_mr_api->get
      EXPORTING
        i_url              = l_url
      IMPORTING
        e_is_folder        = is_folder
        e_content          = l_current
        e_loio             = l_loio
      EXCEPTIONS
        parameter_missing  = 1
        error_occured      = 2
        not_found          = 3
        permission_failure = 4
        OTHERS             = 5.

    IF sy-subrc <> 0.
      CASE sy-subrc.
        WHEN 3.              "* --- mime not found -> go on...
          CLEAR l_current.
        WHEN 4.
          WRITE: /(6) icon_red_light AS ICON, (55) TEXT-007, l_url.
*           Keine Leseberechtigung an Mime-Objekt
          CONTINUE.
        WHEN OTHERS.
          WRITE: /(6) icon_red_light AS ICON, (55) TEXT-008, l_url.
*           Fehler beim Lesen des Mime-Objektes
          CONTINUE.
      ENDCASE.
    ENDIF.

* --- this should not happen...
    IF is_folder = 'X'.
      WRITE: /(6) icon_red_light AS ICON, (55) TEXT-011, l_url.
*       Der angegebene Pfad zeigt auf ein Verzeichnis
      CONTINUE.
    ENDIF.

    l_filename = l_url.
    REPLACE mimepath IN l_filename WITH _rootdir IGNORING CASE.
* --- to be consistent with windows pathes
    TRANSLATE l_filename USING '/\'.
    l_filelength = strlen( l_filename ).
* --- to be sure: it's not the unicode world
* --- so we have a limit for the length of filenames
    IF l_filelength > co_max_length.
      WRITE: /(6) icon_red_light AS ICON, (55) TEXT-035, l_filename.
*       Pfad zu lang! Datei kann nicht exportiert werden!
      CONTINUE.
    ENDIF.

    CLEAR: x, y, l_count, l_filelength.
    REFRESH itab_files.
    l_filelength = xstrlen( l_current ).
    x = l_filelength.
    WHILE x GT 0.
      y = l_count * 1024.
      APPEND l_current+y(x) TO itab_files.
      x = x - 1024.
      l_count = l_count + 1.
    ENDWHILE.

* --- export file to frontend
    CALL METHOD cl_gui_frontend_services=>gui_download
      EXPORTING
        bin_filesize            = l_filelength
        filename                = l_filename
        filetype                = 'BIN'
      IMPORTING
        filelength              = l_filelength
      CHANGING
        data_tab                = itab_files
      EXCEPTIONS
        file_write_error        = 1
        no_batch                = 2
        gui_refuse_filetransfer = 3
        invalid_type            = 4
        no_authority            = 5
        unknown_error           = 6
        header_not_allowed      = 7
        separator_not_allowed   = 8
        filesize_not_allowed    = 9
        header_too_long         = 10
        dp_error_create         = 11
        dp_error_send           = 12
        dp_error_write          = 13
        unknown_dp_error        = 14
        access_denied           = 15
        dp_out_of_memory        = 16
        disk_full               = 17
        dp_timeout              = 18
        file_not_found          = 19
        dataprovider_exception  = 20
        control_flush_error     = 21
        not_supported_by_gui    = 22
        error_no_gui            = 23
        OTHERS                  = 24.

    IF sy-subrc <> 0.
      WRITE: /(6) icon_red_light AS ICON, (55) TEXT-028, l_filename.
*       Fehler beim Download der Datei
      CONTINUE.
    ELSE.
      file_counter = file_counter + 1.
    ENDIF.
    CALL METHOD cl_gui_cfw=>flush.

  ENDLOOP.

  IF NOT itab_ascii IS INITIAL.
    CONCATENATE _rootdir co_loio_file INTO l_filename.

* --- export loio information to frontend
    CALL METHOD cl_gui_frontend_services=>gui_download
      EXPORTING
        filename                = l_filename
        filetype                = 'ASC'
      IMPORTING
        filelength              = l_filelength
      CHANGING
        data_tab                = itab_ascii
      EXCEPTIONS
        file_write_error        = 1
        no_batch                = 2
        gui_refuse_filetransfer = 3
        invalid_type            = 4
        no_authority            = 5
        unknown_error           = 6
        header_not_allowed      = 7
        separator_not_allowed   = 8
        filesize_not_allowed    = 9
        header_too_long         = 10
        dp_error_create         = 11
        dp_error_send           = 12
        dp_error_write          = 13
        unknown_dp_error        = 14
        access_denied           = 15
        dp_out_of_memory        = 16
        disk_full               = 17
        dp_timeout              = 18
        file_not_found          = 19
        dataprovider_exception  = 20
        control_flush_error     = 21
        not_supported_by_gui    = 22
        error_no_gui            = 23
        OTHERS                  = 24.

    IF sy-subrc <> 0.
      WRITE: /(6) icon_red_light AS ICON, (55) TEXT-028, l_filename.
*       Fehler beim Download der Datei
    ENDIF.
    CALL METHOD cl_gui_cfw=>flush.

  ENDIF.  "NOT itab_ascii IS INITIAL

  ULINE.
  WRITE: /(6) icon_write_file AS ICON, (55) TEXT-026, file_counter.
*   Anzahl neu angelegter Dateien
ENDFORM.
