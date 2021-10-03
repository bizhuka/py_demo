class ZCL_AQO_OAOR_MENU_EXT definition
  public
  final
  create public .

public section.
  type-pools ABAP .
  type-pools CNTB .

  interfaces ZIF_AQO_MENU_EXT .

  types TS_OAOR_FILE type ZSAQO_OAOR_FILE .
  types:
    tt_oaor_file TYPE STANDARD TABLE OF ts_oaor_file WITH DEFAULT KEY .
protected section.
private section.

  constants:
    BEGIN OF mc_action,
        attach_root    TYPE ui_func VALUE '_EXT_OAOR_ROOT',
        attach_import  TYPE ui_func VALUE '_EXT_OAOR_IMPORT',
        attach_show    TYPE ui_func VALUE '_EXT_OAOR_SHOW',
        attach_delete  TYPE ui_func VALUE '_EXT_OAOR_DELETE',
      END OF mc_action .
  constants:
    BEGIN OF mc_oaor,
        new_file       TYPE string VALUE 'NEW_FILE',
        new_version    TYPE string VALUE 'NEW_VERSION',
        update_version TYPE string VALUE 'UPDATE_VERSION',
      END OF mc_oaor .
  constants:
    BEGIN OF mc,
        oaor_other TYPE bapibds01-classtype VALUE 'OT',
      END OF mc .
  data MS_DB_ITEM type ZTAQO_OPTION .
  data MV_TCODE type SYTCODE .

  class-methods _CHECK_EXISTS
    importing
      !IV_PACK_ID type ZTAQO_OPTION-PACKAGE_ID
      !IV_OPTION_ID type ZTAQO_OPTION-OPTION_ID
    exporting
      !EV_TASK type E070-TRKORR
      !EV_OK_MESSAGE type CSEQUENCE .
  class-methods _GET_FILES
    importing
      !IV_PACK_ID type ZTAQO_OPTION-PACKAGE_ID
      !IV_OPTION_ID type ZTAQO_OPTION-OPTION_ID
      !IV_FILENAME type CSEQUENCE optional
      !IV_LAST_ONLY type ABAP_BOOL
    exporting
      !ES_OAOR_LAST type TS_OAOR_FILE
      !ET_OAOR_FILE type TT_OAOR_FILE .
  class-methods _DELETE_FILE
    importing
      !IV_PACK_ID type ZTAQO_OPTION-PACKAGE_ID
      !IV_OPTION_ID type ZTAQO_OPTION-OPTION_ID
      !IS_OAOR_FILE type TS_OAOR_FILE .
  class-methods _CHANGE_FILE_NAME
    importing
      !IV_FILE_NAME type CSEQUENCE
    changing
      !CS_FILE type BAPIFILES
    raising
      ZCX_EUI_EXCEPTION .
  class-methods _HAS_VISIBLE_FILES
    importing
      !IV_PACK type ZTAQO_OPTION-PACKAGE_ID
      !IV_OPT type ZTAQO_OPTION-OPTION_ID
    returning
      value(RV_VISIBLE) type ABAP_BOOL .
  methods _DILOAG_SCREEN
    importing
      !IV_DOC_VER_NO type TS_OAOR_FILE-DOC_VER_NO
      !IT_LISTBOX type VRM_VALUES
      !IV_TITLE type CSEQUENCE
    exporting
      !EV_OK type ABAP_BOOL
    changing
      !CV_FILE_NAME type TS_OAOR_FILE-FILE_NAME
      !CV_DESCRIPTION type TS_OAOR_FILE-DESCRIPTION .
  methods _IMPORT_GET_VERSION
    exporting
      !ET_FILE type SBDST_FILES
      !ES_OAOR_FILE type TS_OAOR_FILE
      !EV_OAOR_MODE type STRING
      !EV_EXT type STRING .
  methods _FIND_REQUEST
    importing
      !IS_OAOR_FILE type TS_OAOR_FILE
    changing
      !CV_TASK type E070-TRKORR
      !CV_OK_MESSAGE type CSEQUENCE
    raising
      ZCX_AQO_EXCEPTION .
  methods _ON_IMPORT
    returning
      value(RV_UPDATE) type ABAP_BOOL
    raising
      ZCX_AQO_EXCEPTION .
  methods _ON_SHOW
    importing
      !IV_VIS_ONLY type ABAP_BOOL optional
      !IV_DELETE type ABAP_BOOL optional
    returning
      value(RV_UPDATE) type ABAP_BOOL
    raising
      ZCX_AQO_EXCEPTION .
  methods _ON_DELETE
    returning
      value(RV_UPDATE) type ABAP_BOOL
    raising
      ZCX_AQO_EXCEPTION .
ENDCLASS.



CLASS ZCL_AQO_OAOR_MENU_EXT IMPLEMENTATION.


METHOD ZIF_AQO_MENU_EXT~ADD_BUTTONS.
  DATA lt_menu LIKE ct_menu.
  FIELD-SYMBOLS <ls_menu> LIKE LINE OF lt_menu.

  APPEND INITIAL LINE TO lt_menu ASSIGNING <ls_menu>.
  <ls_menu>-text         = <ls_menu>-quickinfo    = 'Attach'(att).
  <ls_menu>-icon         = icon_attachment.
  <ls_menu>-butn_type    = cntb_btype_menu.
  <ls_menu>-function     = mc_action-attach_root.
  <ls_menu>-par_function = iv_root_func.

  APPEND INITIAL LINE TO lt_menu ASSIGNING <ls_menu>.
  <ls_menu>-text         = <ls_menu>-quickinfo    = 'Add attachment'(aat).
  <ls_menu>-butn_type    = cntb_btype_button.
  <ls_menu>-function     = mc_action-attach_import.
  <ls_menu>-par_function = mc_action-attach_root.

  APPEND INITIAL LINE TO lt_menu ASSIGNING <ls_menu>.
  <ls_menu>-text         = <ls_menu>-quickinfo    = 'Show attachments'(sat).
  <ls_menu>-butn_type    = cntb_btype_button.
  <ls_menu>-function     = mc_action-attach_show.
  <ls_menu>-par_function = mc_action-attach_root.

  APPEND INITIAL LINE TO lt_menu ASSIGNING <ls_menu>.
  <ls_menu>-text         = <ls_menu>-quickinfo    = 'Delete attachment'(dat).
  <ls_menu>-butn_type    = cntb_btype_button.
  <ls_menu>-function     = mc_action-attach_delete.
  <ls_menu>-par_function = mc_action-attach_root.

  " 0 - lv_is_dev, 1 - is_state-in_editor, 2 - lv_view_only, 3 - lv_option_exist
  LOOP AT lt_menu ASSIGNING <ls_menu>.
    CASE <ls_menu>-function.
*        " Just skip
*      WHEN mc_action-base.

      WHEN mc_action-attach_root.
        IF is_state-option_exist <> abap_true OR is_state-is_dev <> abap_true.
          <ls_menu>-hide = abap_true.
        ENDIF.

      WHEN mc_action-attach_import OR mc_action-attach_delete.
        IF is_state-option_exist <> abap_true.
          <ls_menu>-hide = abap_true.
        ENDIF.

        IF is_state-is_dev <> abap_true
           OR is_state-in_editor <> abap_true
           OR is_state-view_only = abap_true.
          <ls_menu>-disabled = abap_true.
          <ls_menu>-quickinfo = 'In DEV editor only!'(ido).
        ENDIF.

      WHEN mc_action-attach_show.
    ENDCASE.
  ENDLOOP.

  APPEND LINES OF lt_menu TO ct_menu.
ENDMETHOD.


METHOD zif_aqo_menu_ext~button_pressed.
  DATA lv_method TYPE string.
  CONCATENATE '_ON' iv_command+9  INTO lv_method.

  TRY.
      ms_db_item = is_db_item.
      mv_tcode   = iv_tcode.
      CALL METHOD me->(lv_method).
    CATCH cx_sy_dyn_call_illegal_method.
      RETURN.
  ENDTRY.

  rv_ok = abap_true.
ENDMETHOD.


METHOD _change_file_name.
  DATA lo_file       TYPE REF TO zcl_eui_file.
  DATA lv_temp_path  TYPE string.
  DATA lv_full_path  TYPE string.
  DATA lv_sep        TYPE char1.
  DATA lv_len        TYPE i.

  " 1-st upload file
  CREATE OBJECT lo_file.
  CONCATENATE cs_file-directory cs_file-filename INTO lv_full_path.
  lo_file->import_from_file( iv_full_path = lv_full_path ).

  " Save to temp dir No need to clean files (cl_gui_frontend_services=>file_delete). SAP gui cleans 'SAP GUI\tmp\' automatically
  cl_gui_frontend_services=>get_temp_directory(
   CHANGING
     temp_dir = lv_temp_path
   EXCEPTIONS
     OTHERS = 1 ).
  IF sy-subrc <> 0.
    zcx_eui_exception=>raise_sys_error( ).
  ENDIF.

  " Add file separator
  cl_gui_frontend_services=>get_file_separator(
   CHANGING
     file_separator = lv_sep ).
  cl_gui_cfw=>flush( ).

  lv_len = strlen( lv_temp_path ) - 1.
  IF lv_temp_path+lv_len(1) <> lv_sep.
    CONCATENATE lv_temp_path lv_sep INTO lv_temp_path.
  ENDIF.

  " Save to sub folter of temp
  lv_full_path = zcl_eui_conv=>guid_create( ).
  CONCATENATE lv_temp_path lv_full_path lv_sep INTO lv_temp_path.

  " 2-nd download with new name
  CONCATENATE lv_temp_path iv_file_name INTO lv_full_path.
  lo_file->download(
   iv_full_path   = lv_full_path
   iv_save_dialog = abap_false ).

  " Change if all ok
  cs_file-directory = lv_temp_path.
  cs_file-filename  = iv_file_name.
ENDMETHOD.


METHOD _check_exists.
  DATA:
    ls_bds_locl TYPE bds_locl,
    lo_error    TYPE REF TO zcx_aqo_exception.

  " select request/task
  CLEAR ev_task.
  TRY.
      zcl_aqo_helper=>find_request( EXPORTING iv_table_name = 'BDS_LOCL'
                                              iv_key1       = iv_pack_id
                                              iv_key2       = mc-oaor_other
                                    CHANGING  cv_task       = ev_task
                                              " cv_request    = rv_request
                                              cv_ok_message = ev_ok_message ).
    CATCH zcx_aqo_exception INTO lo_error.
      CLEAR: "rv_request,
       ev_task.
      MESSAGE lo_error TYPE 'S' DISPLAY LIKE 'E'.
  ENDTRY.

  " If ok
  CHECK ev_task IS NOT INITIAL.

  " exist ?
  SELECT SINGLE * INTO ls_bds_locl
  FROM bds_locl
  WHERE classname = iv_pack_id
    AND classtype = mc-oaor_other.
  CHECK sy-subrc <> 0.

  " Create new
  ls_bds_locl-classname = iv_pack_id.
  ls_bds_locl-classtype = mc-oaor_other.
  ls_bds_locl-lo_class  = 'BDS_LOC2'.
  ls_bds_locl-ph_class  = 'BDS_POC2'.
  ls_bds_locl-re_class  = 'BDS_REC2'.
  ls_bds_locl-tabname   = 'BDS_CONN05'.
  ls_bds_locl-log_level = 0. " Or 2 ?
  ls_bds_locl-crea_user = sy-uname.
  CONCATENATE sy-datum sy-uzeit INTO ls_bds_locl-crea_time.

  " Update DB
  INSERT bds_locl FROM ls_bds_locl.
ENDMETHOD.


METHOD _delete_file.
  DATA:
    lv_key           TYPE sbdst_object_key,
    lt_bds_signature TYPE sbdst_signature,
    ls_bds_signature TYPE bapisignat.

  " Subfolder in OAOR (and classname = package_id)
  lv_key = iv_option_id.

  " Prepare signature
  MOVE-CORRESPONDING is_oaor_file TO ls_bds_signature.
  APPEND ls_bds_signature TO lt_bds_signature.

  cl_bds_document_set=>delete(
    EXPORTING
      classname      = iv_pack_id
      classtype      = mc-oaor_other
      object_key     = lv_key
      x_force_delete = abap_true
    CHANGING
      signature      = lt_bds_signature
    EXCEPTIONS
      OTHERS         = 7 ).
  IF sy-subrc <> 0.
    MESSAGE ID sy-msgid TYPE 'S' NUMBER sy-msgno WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4 DISPLAY LIKE 'E'.
    RETURN.
  ENDIF.
ENDMETHOD.


METHOD _diloag_screen.
  " Show in screen PARAMETERS:
  DATA ls_dyn_scr  TYPE REF TO zsaqo_oaor_dialog.
  DATA lo_screen   TYPE REF TO zcl_eui_screen.
  DATA lo_err      TYPE REF TO zcx_eui_exception.
  DATA lv_input    TYPE screen-input.
  DATA lv_cmd      TYPE syucomm.

  CLEAR ev_ok.

  " Fill scrren with values
  CREATE DATA ls_dyn_scr.
  ls_dyn_scr->p_3_pack   = ms_db_item-package_id.
  ls_dyn_scr->p_3_opt    = ms_db_item-option_id.
  ls_dyn_scr->p_3_file   = cv_file_name.
  ls_dyn_scr->p_3_vers   = iv_doc_ver_no.
  ls_dyn_scr->p_3_desc   = cv_description.

  " Create screen manager
  TRY.
      DATA lv_prog TYPE sycprog.
      CONCATENATE zcl_aqo_menu_handler=>mc_prog-editor `OAOR_SCR` INTO lv_prog.
      CREATE OBJECT lo_screen
        EXPORTING
          iv_dynnr   = zcl_eui_screen=>mc_dynnr-dynamic
          iv_cprog   = lv_prog
          ir_context = ls_dyn_scr.

      DATA ls_status TYPE zcl_eui_manager=>ts_status.
      ls_status-title = iv_title. " 'New file info'(nfi). " Set pf-status & text
      lo_screen->set_status( ls_status ).
    CATCH zcx_eui_exception INTO lo_err.
      MESSAGE lo_err TYPE 'S' DISPLAY LIKE 'E'.
      RETURN.
  ENDTRY.

  " Ok & Cancel
  lv_input = '1'.
  IF me->mv_tcode <> zcl_aqo_menu_handler=>mc_prog-editor_tcode OR zcl_aqo_helper=>is_dev_mandt( ) <> abap_true.
    APPEND 'OK' TO lo_screen->ms_status-exclude.
    lv_input = '0'.
  ENDIF.

  " Static PF status no need on_pbo_event.
  lo_screen->customize( name = 'P_3_PACK'   input = '0' ).
  lo_screen->customize( name = 'P_3_OPT'    input = '0' ).
  " Can load with different name
  lo_screen->customize( name = 'P_3_FILE'   required   = '1'
                                            it_listbox = it_listbox ).
  lo_screen->customize( name = 'P_3_VERS'   input = '0' ).
  lo_screen->customize( name = 'P_3_DESC'   input = lv_input ).
  lo_screen->customize( name = 'P_3_VIS'    input = lv_input ).

  " As popup
  DATA lv_col_end TYPE i.
  lo_screen->get_dimension( IMPORTING ev_col_end = lv_col_end ).
  lo_screen->popup( iv_col_end = lv_col_end ).

  " Process action
  lv_cmd = lo_screen->show( ).
  CHECK lv_cmd = zif_eui_manager=>mc_cmd-ok.

  cv_description = ls_dyn_scr->p_3_desc.
  " !now index in list box!
  cv_file_name   = ls_dyn_scr->p_3_file.
  ev_ok                    = abap_true.
ENDMETHOD.


METHOD _find_request.
  DATA ls_bds       TYPE bapibds01.
  DATA lt_entry     TYPE STANDARD TABLE OF bapicomfil WITH DEFAULT KEY.
  DATA lr_entry     TYPE REF TO bapicomfil.
  DATA lt_signature TYPE STANDARD TABLE OF bapisignat WITH DEFAULT KEY.
  DATA lr_signature TYPE REF TO bapisignat.

  ls_bds-classname = is_oaor_file-package_id.
  ls_bds-classtype = mc-oaor_other.
  ls_bds-client    = sy-mandt.
  ls_bds-objkey    = is_oaor_file-option_id.

  APPEND INITIAL LINE TO lt_signature REFERENCE INTO lr_signature.
  lr_signature->doc_count  = is_oaor_file-comp_count. " c_index.
  lr_signature->doc_id     = is_oaor_file-doc_id.
  lr_signature->doc_ver_no = is_oaor_file-doc_ver_no.
  lr_signature->doc_var_id = is_oaor_file-doc_var_id.
  lr_signature->doc_var_tg = 'OR'.

  CALL FUNCTION 'BDS_BUSINESSDOCUMENT_GET_TP'
    EXPORTING
      logical_system   = ls_bds-log_system
      classname        = ls_bds-classname
      classtype        = ls_bds-classtype
      client           = ls_bds-client
      object_key       = ls_bds-objkey
    TABLES
      signature        = lt_signature
      commfile_entries = lt_entry
    EXCEPTIONS
      OTHERS           = 7.
  IF sy-subrc <> 0.
    zcx_aqo_exception=>raise_sys_error( ).
  ENDIF.

  DATA lt_e071 TYPE zcl_aqo_helper=>tt_e071.
  DATA ls_e071 LIKE LINE OF lt_e071.
  LOOP AT lt_entry REFERENCE INTO lr_entry.
    MOVE-CORRESPONDING lr_entry->* TO ls_e071.
    APPEND ls_e071 TO lt_e071.
  ENDLOOP.

  " Find new task or this is OK?
  IF cv_task IS INITIAL.

    " Find first
    DATA lr_e071 TYPE REF TO e071.
    LOOP AT lt_e071 REFERENCE INTO lr_e071.
      SELECT SINGLE e070~trkorr INTO cv_task
      FROM e070 INNER JOIN e071 ON e071~trkorr = e070~trkorr
      WHERE e071~pgmid    = lr_e071->pgmid
        AND e071~object   = lr_e071->object
        AND e071~obj_name = lr_e071->obj_name
        " @see ZCL_AQO_HELPER=>FIND_REQUEST
        AND ( e070~trstatus = 'D' OR e070~trstatus = 'L' ) AND e070~strkorr <> space.

      CHECK cv_task IS NOT INITIAL.
      EXIT.
    ENDLOOP.
  ENDIF.

  DATA lv_request TYPE e070-trkorr.
  zcl_aqo_helper=>put_2_request( EXPORTING it_e071       = lt_e071
                                           " it_e071k      = lt_e071k
                                 IMPORTING ev_request    = lv_request
                                 CHANGING  cv_task       = cv_task
                                           cv_ok_message = cv_ok_message ).
  " Ok
  CHECK lv_request IS NOT INITIAL AND cv_task IS NOT INITIAL.
  MESSAGE s039(zaqo_message) WITH is_oaor_file-file_name is_oaor_file-doc_ver_no lv_request INTO cv_ok_message.
ENDMETHOD.


METHOD _get_files.
  DATA:
    lv_key               TYPE sbdst_object_key,
    lt_sbdst_signature   TYPE sbdst_signature,
    ls_sbdst_signature   TYPE REF TO bapisignat,
    lt_sbdst_components2 TYPE sbdst_components2,
    ls_sbdst_components2 TYPE REF TO bapicompo2,
    ls_oaor_file         TYPE REF TO ts_oaor_file,
    lt_doc_id            TYPE SORTED TABLE OF ts_oaor_file-doc_id WITH UNIQUE KEY table_line,
    lv_field             TYPE string.
  FIELD-SYMBOLS:
    <l_val>              TYPE any.

  CLEAR:
    es_oaor_last,
    et_oaor_file.

  " Subfolder in OAOR (and classname = package_id)
  lv_key = iv_option_id.

  " Finding the right documents
  cl_bds_document_set=>get_info(
   EXPORTING
    classname           = iv_pack_id
    classtype           = mc-oaor_other
    object_key          = lv_key
   IMPORTING
    extended_components = lt_sbdst_components2
   CHANGING
    signature           = lt_sbdst_signature
   EXCEPTIONS
    OTHERS              = 7 ).
  CHECK sy-subrc = 0.

  " lt_sbdst_signature structure is complex
  LOOP AT lt_sbdst_signature REFERENCE INTO ls_sbdst_signature.

    AT NEW doc_count.
      " Create new item
      APPEND INITIAL LINE TO et_oaor_file REFERENCE INTO ls_oaor_file.
      ls_oaor_file->doc_id     = ls_sbdst_signature->doc_id.
      ls_oaor_file->doc_ver_no = ls_sbdst_signature->doc_ver_no.
      ls_oaor_file->doc_var_id = ls_sbdst_signature->doc_var_id.
      ls_oaor_file->comp_count = ls_sbdst_signature->comp_count.

      " Concatenate 2 tables
      READ TABLE lt_sbdst_components2 REFERENCE INTO ls_sbdst_components2
       INDEX ls_sbdst_signature->doc_count.
      ls_oaor_file->objid     = ls_sbdst_components2->objid.
      ls_oaor_file->file_name = ls_sbdst_components2->file_name.
      ls_oaor_file->class     = ls_sbdst_components2->class.
    ENDAT.

    " Find field by name
    lv_field = ls_sbdst_signature->prop_name.
    IF lv_field = 'BDS_KEYWORD'.
      lv_field = ls_sbdst_signature->prop_value.
    ENDIF.

    ASSIGN COMPONENT lv_field OF STRUCTURE ls_oaor_file->* TO <l_val>.
    CHECK sy-subrc = 0.

    " Set flag
    IF ls_sbdst_signature->prop_name = 'BDS_KEYWORD'.
      <l_val> = abap_true.
    ELSE.
      <l_val> = ls_sbdst_signature->prop_value.
    ENDIF.
  ENDLOOP.

  " Apply filters
  IF iv_filename IS NOT INITIAL.
    DELETE et_oaor_file WHERE file_name <> iv_filename.
  ENDIF.

  " Max versions first
  SORT et_oaor_file BY doc_id doc_ver_no DESCENDING.

  " Fill other fields
  LOOP AT et_oaor_file REFERENCE INTO ls_oaor_file.
    " Mark current version
    READ TABLE lt_doc_id TRANSPORTING NO FIELDS
     WITH TABLE KEY table_line = ls_oaor_file->doc_id.
    IF sy-subrc <> 0.
      INSERT ls_oaor_file->doc_id INTO TABLE lt_doc_id.
      ls_oaor_file->last_version = abap_true.
    ENDIF.
  ENDLOOP.

  " Only last
  IF iv_last_only = abap_true.
    DELETE et_oaor_file WHERE last_version <> abap_true.
  ENDIF.

  " Max versions last
  SORT et_oaor_file BY doc_id doc_ver_no ASCENDING.

  LOOP AT et_oaor_file REFERENCE INTO ls_oaor_file.
    ls_oaor_file->tabix      = sy-tabix.
    ls_oaor_file->package_id = iv_pack_id.
    ls_oaor_file->option_id	 = iv_option_id.

    " Create at
    ls_oaor_file->created_at_date      = ls_oaor_file->created_at(8).
    ls_oaor_file->created_at_time      = ls_oaor_file->created_at+8(6).

    " Changed at
    ls_oaor_file->last_changed_at_date = ls_oaor_file->last_changed_at(8).
    ls_oaor_file->last_changed_at_time = ls_oaor_file->last_changed_at+8(6).
  ENDLOOP.

  " Get last version for 1 file
  CHECK iv_filename IS NOT INITIAL
    AND es_oaor_last IS REQUESTED.

  READ TABLE et_oaor_file INTO es_oaor_last
   WITH KEY last_version = abap_true
            file_name    = iv_filename.
ENDMETHOD.


METHOD _has_visible_files.
***  DATA:
***    ls_visible   TYPE ts_visible,
***    lr_visible   TYPE REF TO ts_visible,
***    lt_oaor_file TYPE tt_oaor_file.
***
***  READ TABLE mt_visible REFERENCE INTO lr_visible
***   WITH TABLE KEY pack = iv_pack
***                  opt  = iv_opt.
***
***  " Serach for the first time
***  IF sy-subrc <> 0.
***    ls_visible-pack = iv_pack.
***    ls_visible-opt  = iv_opt.
***
***    " Get all files
***    _oaor_get_files(
***     EXPORTING
***       iv_pack_id   = ls_visible-pack
***       iv_option_id = ls_visible-opt
***       iv_last_only = abap_true
***     IMPORTING
***       et_oaor_file = lt_oaor_file ).
***
***    " Only visible and new files
***    DELETE lt_oaor_file WHERE visible <> abap_true.
***    IF lt_oaor_file IS NOT INITIAL.
***      ls_visible-visible = abap_true.
***    ENDIF.
***
***    " Insert for speed
***    INSERT ls_visible INTO TABLE mt_visible REFERENCE INTO lr_visible.
***  ENDIF.
***
***  " And return
***  rv_visible = lr_visible->visible.
ENDMETHOD.


METHOD _import_get_version.
  DATA ls_result_oaor    LIKE es_oaor_file.
  DATA lt_many_file      TYPE tt_oaor_file.
  DATA lv_key            TYPE sbdst_object_key.
  DATA lv_task           TYPE e070-trkorr.
  DATA lv_message        TYPE string.
  DATA lr_file           TYPE REF TO bapifiles.
  DATA ls_screen_file    TYPE ts_oaor_file.
  DATA lt_file_table     TYPE filetable.
  DATA ls_file_table     TYPE REF TO file_table.
  DATA lv_rc             TYPE i.
  DATA lv_action         TYPE i.
  DATA lv_ok             TYPE abap_bool.
  DATA lt_listbox        TYPE vrm_values.
  DATA lv_listbox_ind    TYPE num2.
  DATA lo_error          TYPE REF TO zcx_eui_exception.
  DATA lv_title          TYPE lvc_s_layo-grid_title.

  FIELD-SYMBOLS:
    <ls_result_oaor> TYPE ts_oaor_file,
    <ls_listbox>     TYPE vrm_value.

  " All is empty
  CLEAR:
    et_file,
    es_oaor_file,
    ev_oaor_mode,
    ev_ext.

  " Subfolder in OAOR (and classname = package_id)
  lv_key = ms_db_item-option_id.

  " Get file info
  cl_gui_frontend_services=>file_open_dialog(
   EXPORTING
     multiselection = abap_false
   CHANGING
     file_table     = lt_file_table
     rc             = lv_rc
     user_action    = lv_action
   EXCEPTIONS
     OTHERS      = 1 ).
  CHECK sy-subrc = 0 AND lt_file_table[] IS NOT INITIAL.

  " Get 1-st
  READ TABLE lt_file_table REFERENCE INTO ls_file_table INDEX 1.
  CHECK sy-subrc = 0.

  " Extract info
  APPEND INITIAL LINE TO et_file REFERENCE INTO lr_file.
  zcl_eui_file=>split_file_path(
   EXPORTING
     iv_fullpath  = ls_file_table->filename
   IMPORTING
     ev_path      = lr_file->directory
     ev_filename  = lr_file->filename
     ev_extension = ev_ext ).

  " Create or not
  _check_exists(
   EXPORTING
     iv_pack_id    = ms_db_item-package_id
     iv_option_id  = ms_db_item-option_id
   IMPORTING
     ev_task       = lv_task
     ev_ok_message = lv_message ).
  IF lv_message IS NOT INITIAL.
    MESSAGE lv_message TYPE 'S'.
  ENDIF.

  " Nope
  CHECK lv_task IS NOT INITIAL.

  " Always 1 file
  lr_file->comp_count = lr_file->doc_count = 1.
  " Always in UPPER CASE (ID). TODO mac or linux ? (case sensitive)
  TRANSLATE lr_file->filename TO UPPER CASE.

  " Read many files. Only last
  _get_files(
   EXPORTING
    iv_pack_id   = ms_db_item-package_id
    iv_option_id = ms_db_item-option_id
    " All last files iv_filename  = ls_file-filename
    iv_last_only = abap_true
   IMPORTING
    et_oaor_file = lt_many_file ).

**********************************************************************
  " Prepare listbox
**********************************************************************

  " Always 1-st position
  APPEND INITIAL LINE TO lt_listbox ASSIGNING <ls_listbox>.
  <ls_listbox>-key  = '01'.
  <ls_listbox>-text = lr_file->filename.

  " Other files list
  LOOP AT lt_many_file ASSIGNING <ls_result_oaor> WHERE file_name <> lr_file->filename.
    " Add as pair
    APPEND INITIAL LINE TO lt_listbox ASSIGNING <ls_listbox>.
    lv_listbox_ind    = sy-tabix.
    <ls_listbox>-key  = lv_listbox_ind.
    <ls_listbox>-text = <ls_result_oaor>-file_name.
  ENDLOOP.

**********************************************************************
  " Detect MODE
**********************************************************************

  " New or existeng item
  READ TABLE lt_many_file INTO ls_result_oaor
   WITH KEY file_name = lr_file->filename.
  IF ls_result_oaor IS INITIAL.
    ls_result_oaor-description = ls_result_oaor-file_name = lr_file->filename.
    ev_oaor_mode = mc_oaor-new_file.
    MESSAGE s036(zaqo_message) INTO lv_title.

  ELSEIF sy-datum = ls_result_oaor-last_changed_at_date.
    ev_oaor_mode = mc_oaor-update_version.
    MESSAGE s038(zaqo_message) WITH ls_result_oaor-doc_ver_no INTO lv_title.

  ELSE.
    ev_oaor_mode = mc_oaor-new_version.
    MESSAGE s037(zaqo_message) WITH ls_result_oaor-doc_ver_no INTO lv_title.
  ENDIF.

  " Also show as message
  MESSAGE lv_title TYPE 'S'.
**********************************************************************

  " Only now SET index in LSITBOX
  ls_result_oaor-file_name = '01'.

  ls_screen_file = ls_result_oaor.
  _diloag_screen(
   EXPORTING
     iv_doc_ver_no  = ls_screen_file-doc_ver_no
     it_listbox     = lt_listbox[]
     iv_title       = lv_title
   IMPORTING
     ev_ok          = lv_ok
   CHANGING
     cv_file_name   = ls_screen_file-file_name
     cv_description = ls_screen_file-description ).
  CHECK lv_ok = abap_true.

  " get from index
  DO 1 TIMES.
    " Get new name
    lv_listbox_ind = ls_screen_file-file_name.
    READ TABLE lt_listbox ASSIGNING <ls_listbox>
     WITH KEY key = lv_listbox_ind.

    " Get name by index
    CHECK sy-subrc  = 0.
    ls_result_oaor-file_name = <ls_listbox>-text.

**********************************************************************
    " Choosed another file name
**********************************************************************
    CHECK lv_listbox_ind <> '01'.

    " Read again with a new name
    READ TABLE lt_many_file INTO ls_result_oaor
     WITH KEY file_name = <ls_listbox>-text.
    CHECK sy-subrc = 0.

    IF sy-datum = ls_result_oaor-last_changed_at_date.
      ev_oaor_mode = mc_oaor-update_version.
      MESSAGE s038(zaqo_message) WITH ls_result_oaor-doc_ver_no.

    ELSE.
      ev_oaor_mode = mc_oaor-new_version.
      MESSAGE s037(zaqo_message) WITH ls_result_oaor-doc_ver_no.
    ENDIF.

    " Rename file
    TRY.
        _change_file_name(
          EXPORTING
            iv_file_name = ls_result_oaor-file_name
          CHANGING
            cs_file      = lr_file->* ).
      CATCH zcx_eui_exception INTO lo_error.
        MESSAGE lo_error TYPE 'S' DISPLAY LIKE 'E'.
        RETURN.
    ENDTRY.
  ENDDO.

  " Get modified
  ls_result_oaor-description = ls_screen_file-description.
  " Return result in the end
  es_oaor_file               = ls_result_oaor.
ENDMETHOD.


METHOD _on_delete.
  CHECK zcl_eui_screen=>confirm(
      iv_title    = 'Confirmation'(cnf)
      iv_question = 'Deleting file is irreversible. Continue?'(def)
      iv_icon_1   = 'ICON_DELETE_TEMPLATE' ) = abap_true.

  " Delete in attachments
  _on_show( iv_delete = abap_true ).
ENDMETHOD.


METHOD _on_import.
  DATA lt_file           TYPE sbdst_files.
  DATA lr_file           TYPE REF TO bapifiles.
  DATA ls_oaor_file      TYPE ts_oaor_file.
  DATA lv_oaor_mode      TYPE string.
  DATA lv_ext            TYPE string.
  DATA lt_property       TYPE STANDARD TABLE OF bapiproper WITH DEFAULT KEY.
  DATA lr_property       TYPE REF TO bapiproper.
  DATA lv_ar_object      TYPE toadv-ar_object.
  DATA lt_bds_signature  TYPE sbdst_signature.
  DATA ls_bds_signature  TYPE bapisignat.
  DATA lv_key            TYPE sbdst_object_key.
  DATA lv_new_doc_ver_no TYPE sbdst_doc_ver_no.
  DATA lv_task           TYPE e070-trkorr.
  DATA lv_message        TYPE string.
  DATA lv_last_index     TYPE i.

  " Get new file info
  _import_get_version(
   IMPORTING
     et_file      = lt_file
     es_oaor_file = ls_oaor_file " new file
     ev_oaor_mode = lv_oaor_mode
     ev_ext       = lv_ext ).
  CHECK ls_oaor_file IS NOT INITIAL.

  " Only 1 file
  READ TABLE lt_file REFERENCE INTO lr_file INDEX 1.
  ls_bds_signature-doc_count = lr_file->doc_count.

  " always equal to file name (Case sensetive)
  APPEND INITIAL LINE TO lt_property REFERENCE INTO lr_property.
  lr_property->prop_name  = 'DESCRIPTION'.
  lr_property->prop_value = ls_oaor_file-description.

  APPEND INITIAL LINE TO lt_property REFERENCE INTO lr_property.
  lr_property->prop_name  = 'BDS_DOCUMENTCLASS'.
  lr_property->prop_value = lv_ext.

  APPEND INITIAL LINE TO lt_property REFERENCE INTO lr_property.
  lr_property->prop_name  = 'LANGUAGE'.
  lr_property->prop_value = sy-langu.

**********************************************************************
  " Subfolder in OAOR (and classname = package_id)
  lv_key = ms_db_item-option_id. " ms_db_item-option_id

  CASE lv_oaor_mode.

      " First version
    WHEN mc_oaor-new_file.

      " Detect folder  'BDS_ATTACH' is first
      SELECT SINGLE ar_object INTO lv_ar_object
      FROM toadv
      WHERE standard = abap_true.
      CHECK sy-subrc = 0.

      APPEND INITIAL LINE TO lt_property REFERENCE INTO lr_property.
      lr_property->prop_name  = 'BDS_DOCUMENTTYPE'.
      lr_property->prop_value = lv_ar_object.

      " Convert to another table
      LOOP AT lt_property REFERENCE INTO lr_property.
        MOVE-CORRESPONDING lr_property->* TO ls_bds_signature.
        APPEND ls_bds_signature TO lt_bds_signature.
      ENDLOOP.

      cl_bds_document_set=>create_with_files(
         EXPORTING
           classname       = ms_db_item-package_id
           classtype       = mc-oaor_other
         CHANGING
           object_key      = lv_key
           signature       = lt_bds_signature
           files           = lt_file
         EXCEPTIONS
           OTHERS          = 7 ).
      IF sy-subrc = 0.
        " new version
        _get_files(
         EXPORTING
          iv_pack_id   = ms_db_item-package_id
          iv_option_id = ms_db_item-option_id
          iv_filename  = lr_file->filename
          iv_last_only = abap_true
         IMPORTING
          es_oaor_last = ls_oaor_file ).
      ELSE.
        zcx_aqo_exception=>raise_sys_error( ).
      ENDIF.

**********************************************************************
      " Set new version
    WHEN mc_oaor-new_version.
      cl_bds_document_set=>create_version_with_files(
         EXPORTING
           classname       = ms_db_item-package_id
           classtype       = mc-oaor_other
           object_key      = lv_key
           doc_id          = ls_oaor_file-doc_id
           doc_ver_no      = ls_oaor_file-doc_ver_no
           doc_var_id      = ls_oaor_file-doc_var_id
         IMPORTING
           new_doc_ver_no  = lv_new_doc_ver_no
         CHANGING
           files           = lt_file
           properties      = lt_property
         EXCEPTIONS
           OTHERS          = 7 ).
      IF sy-subrc = 0.
        ls_oaor_file-doc_ver_no = lv_new_doc_ver_no.
      ELSE.
        zcx_aqo_exception=>raise_sys_error( ).
      ENDIF.

**********************************************************************
      " Update existing
    WHEN mc_oaor-update_version.
      cl_bds_document_set=>update_with_files(
       EXPORTING
        classname       = ms_db_item-package_id
        classtype       = mc-oaor_other
        object_key       = lv_key
        doc_id          = ls_oaor_file-doc_id
        doc_ver_no      = ls_oaor_file-doc_ver_no
        doc_var_id      = ls_oaor_file-doc_var_id
        x_force_update  = abap_true
       CHANGING
        files           = lt_file
        properties      = lt_property
       EXCEPTIONS
        OTHERS          = 7 ).
      IF sy-subrc <> 0.
        zcx_aqo_exception=>raise_sys_error( ).
      ENDIF.

    WHEN OTHERS.
      zcx_aqo_exception=>raise_dump( iv_message = 'Please check OAOR mode'(poa) ).
  ENDCASE.

  " Put new file in transport
  _find_request( EXPORTING is_oaor_file  = ls_oaor_file
                 CHANGING  cv_task       = lv_task
                           cv_ok_message = lv_message ).
  IF lv_message IS NOT INITIAL.
    MESSAGE lv_message TYPE 'S'.
  ENDIF.

**********************************************************************

  " Read previous
  DATA lt_all_version TYPE tt_oaor_file.
  _get_files(
   EXPORTING
    iv_pack_id   = ms_db_item-package_id
    iv_option_id = ms_db_item-option_id
    iv_filename  = lr_file->filename
    iv_last_only = abap_false
   IMPORTING
    et_oaor_file = lt_all_version ).

  " Delete obselete data
  lv_last_index = lines( lt_all_version ).
  lv_last_index = lv_last_index - ms_db_item-prev_value_cnt.
  DO lv_last_index TIMES.
    READ TABLE lt_all_version INTO ls_oaor_file INDEX sy-index.
    CHECK sy-subrc = 0.

    _delete_file(
      iv_pack_id   = ms_db_item-package_id
      iv_option_id = ms_db_item-option_id
      is_oaor_file = ls_oaor_file ).
  ENDDO.
ENDMETHOD.


METHOD _on_show.
  DATA:
    lt_oaor_file TYPE tt_oaor_file,
    ls_oaor_file TYPE REF TO ts_oaor_file,
    lt_return    TYPE STANDARD TABLE OF ddshretval WITH DEFAULT KEY,
    ls_return    TYPE REF TO ddshretval,
    ls_object_id TYPE sdokobject,
    lt_info      TYPE STANDARD TABLE OF sdokfilaci,
    ls_info      TYPE REF TO sdokfilaci,
    lt_text      TYPE STANDARD TABLE OF sdokcntasc,
    lt_bin       TYPE STANDARD TABLE OF sdokcntbin,
    lv_filetype  TYPE char10,
    lv_file_size TYPE i,
    lv_index     TYPE i,
    lv_message   TYPE string,
    lv_task      TYPE e070-trkorr,
    lo_file      TYPE REF TO zcl_eui_file,
    lo_error     TYPE REF TO zcx_eui_exception.
  FIELD-SYMBOLS:
   <lt_table>   TYPE STANDARD TABLE.

  _get_files(
   EXPORTING
     iv_pack_id   = ms_db_item-package_id
     iv_option_id = ms_db_item-option_id
     iv_last_only = abap_false
   IMPORTING
     et_oaor_file = lt_oaor_file ).

  " Visible for end users
  DO 1 TIMES.
    CHECK iv_vis_only = abap_true.

    " Hide tech files
    DELETE lt_oaor_file WHERE last_version <> abap_true.
    lv_index = lines( lt_oaor_file ).

    " Oops!
    CHECK lv_index = 0.
    MESSAGE 'No user guide was found'(nug) TYPE 'S' DISPLAY LIKE 'W'.
    RETURN.
  ENDDO.

  " Just read first item
  IF lv_index = 1.
    READ TABLE lt_oaor_file REFERENCE INTO ls_oaor_file INDEX 1.
  ELSE.
    " Show dialog
    CALL FUNCTION 'F4IF_INT_TABLE_VALUE_REQUEST'
      EXPORTING
        ddic_structure   = 'ZSAQO_OAOR_FILE_F4'
        retfield         = 'TABIX'
        callback_program = 'SAPLZFG_AQO_MENU'
        callback_form    = 'CALLBACK_OAOR_F4'
        value_org        = 'S'
      TABLES
        value_tab        = lt_oaor_file
        return_tab       = lt_return
      EXCEPTIONS
        OTHERS           = 3.
    CHECK sy-subrc = 0.

    " First item
    READ TABLE lt_return REFERENCE INTO ls_return INDEX 1.
    CHECK sy-subrc = 0.

    " Read by TABIX in table
    lv_index = ls_return->fieldval.
    READ TABLE lt_oaor_file REFERENCE INTO ls_oaor_file
      WITH KEY tabix = lv_index.
  ENDIF.

  " Is Ok
  CHECK sy-subrc = 0.

  " delete
  IF iv_delete = abap_true.
    " Request for deleting file
    _check_exists(
     EXPORTING
       iv_pack_id    = ms_db_item-package_id
       iv_option_id  = ms_db_item-option_id
     IMPORTING
       ev_task       = lv_task
       ev_ok_message = lv_message ).
    IF lv_message IS NOT INITIAL.
      MESSAGE lv_message TYPE 'S'.
    ENDIF.

    IF lv_task IS NOT INITIAL.
      _delete_file(
         iv_pack_id   = ms_db_item-package_id
         iv_option_id = ms_db_item-option_id
         is_oaor_file = ls_oaor_file->*  ).
    ENDIF.

    " Go out
    RETURN.
  ENDIF.

  MOVE-CORRESPONDING ls_oaor_file->* TO ls_object_id.
  CALL FUNCTION 'SDOK_PHIO_LOAD_CONTENT'
    EXPORTING
      object_id           = ls_object_id
      text_as_stream      = abap_true
    TABLES
      file_access_info    = lt_info
      file_content_ascii  = lt_text
      file_content_binary = lt_bin
    EXCEPTIONS
      OTHERS              = 5.
  CHECK sy-subrc = 0.

  READ TABLE lt_info REFERENCE INTO ls_info INDEX 1.
  CHECK sy-subrc = 0.

  " Text or binary
  IF lt_bin[] IS NOT INITIAL.
    ASSIGN lt_bin  TO <lt_table>.
    lv_filetype  = 'BIN'.
    lv_file_size = ls_info->file_size.
  ELSE.
    ASSIGN lt_text TO <lt_table>.
    lv_filetype  = 'ASC'.
  ENDIF.

  " Download and open
  CREATE OBJECT lo_file.
  TRY.
      lo_file->import_from_binary(
       it_table  = <lt_table>
       iv_length = lv_file_size ).

      lo_file->download(
        iv_full_path   = ls_oaor_file->file_name
        iv_filetype    = lv_filetype
        iv_save_dialog = abap_true ).

      lo_file->open( ).
    CATCH zcx_eui_exception INTO lo_error.
      zcx_aqo_exception=>raise_sys_error( io_error = lo_error ).
  ENDTRY.
ENDMETHOD.
ENDCLASS.
