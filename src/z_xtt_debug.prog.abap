*&---------------------------------------------------------------------*
*&---------------------------------------------------------------------*
REPORT z_xtt_debug.

PARAMETERS:
  p_path  TYPE string OBLIGATORY,
  p_class TYPE text30 OBLIGATORY.


CLASS lcl_report DEFINITION FINAL FRIENDS zcl_aqo_option.
  PUBLIC SECTION.
    DATA:
      r_cprog TYPE RANGE OF sy-cprog READ-ONLY.

    METHODS:
      constructor,

      f4_full_path,

      start_of_selection,

      in_debug
        IMPORTING
          iv_cprog TYPE sycprog
        CHANGING
          cv_debug TYPE abap_bool.
ENDCLASS.

CLASS lcl_report IMPLEMENTATION.
  METHOD constructor.
    TRY.
        zcl_aqo_option=>create(
          iv_package_id = 'ZHR_UTIL_XTT'     " #EC NOTEXT Package
          iv_option_id  = 'TEST'             " #EC NOTEXT
          io_data       = me
         ).
      CATCH zcx_aqo_exception INTO DATA(lo_error).
        MESSAGE lo_error TYPE 'S' DISPLAY LIKE 'E'.
        RETURN.
    ENDTRY.
  ENDMETHOD.

  METHOD f4_full_path.
    DATA          lt_file     TYPE filetable.
    DATA          lv_action   TYPE i.
    DATA          lv_rc       TYPE i.
    FIELD-SYMBOLS <ls_file>   LIKE LINE OF lt_file.

    cl_gui_frontend_services=>file_open_dialog(
      EXPORTING
        window_title      = 'Path to template'
      CHANGING
        file_table        = lt_file
        user_action       = lv_action
        rc                = lv_rc ).
    CHECK lv_action = cl_gui_frontend_services=>action_ok.

    READ TABLE lt_file ASSIGNING <ls_file> INDEX 1.
    CHECK sy-subrc = 0.

    " Path to template
    DATA lv_fullpath TYPE string.
    p_path = lv_fullpath = <ls_file>-filename.

    " Auto detect
    TRANSLATE lv_fullpath TO UPPER CASE.
    IF lv_fullpath CP '*XLSX'.
      p_class = 'ZCL_XTT_EXCEL_XLSX'.
    ELSEIF lv_fullpath CP '*DOCX'.
      p_class = 'ZCL_XTT_WORD_DOCX'.
    ELSEIF lv_fullpath CP '*PDF' OR lv_fullpath CP '*XDP'.
      p_class = 'ZCL_XTT_PDF'.
    ELSEIF lv_fullpath CP '*WORD*XML'.
      p_class = 'ZCL_XTT_WORD_XML'.
    ELSEIF lv_fullpath CP '*EXCEL*XML'.
      p_class = 'ZCL_XTT_EXCEL_XML'.
    ENDIF.
    " TODO set p_class
  ENDMETHOD.

  METHOD start_of_selection.
    DATA lo_debug TYPE REF TO zcl_xtt_debug.
    DATA lo_xtt   TYPE REF TO zcl_xtt.

    CREATE OBJECT lo_debug.
    lo_xtt = lo_debug->load_all( iv_fullpath = p_path
                                 iv_class    = p_class ).
    lo_xtt->download( ).
  ENDMETHOD.

  METHOD in_debug.
    CHECK r_cprog[] IS NOT INITIAL
      AND iv_cprog IN r_cprog[].
    cv_debug = abap_true.
  ENDMETHOD.
ENDCLASS.


INITIALIZATION.
  DATA go_report TYPE REF TO lcl_report.
  CREATE OBJECT go_report.

AT SELECTION-SCREEN ON VALUE-REQUEST FOR p_path.
  go_report->f4_full_path(  ).

START-OF-SELECTION.
  go_report->start_of_selection( ).

FORM in_debug USING    iv_cprog TYPE sycprog
              CHANGING cv_debug TYPE abap_bool.

  DATA lo_report TYPE REF TO lcl_report.
  CREATE OBJECT lo_report.

  lo_report->in_debug( EXPORTING iv_cprog = iv_cprog
                       CHANGING  cv_debug = cv_debug ).
ENDFORM.
