*&---------------------------------------------------------------------*
*&---------------------------------------------------------------------*
REPORT z_aqo_save_data.

PARAMETERS:
  p_exp RADIOBUTTON GROUP gr1 DEFAULT 'X',
  p_imp RADIOBUTTON GROUP gr1.


CLASS lcl_main DEFINITION FINAL.
  PUBLIC SECTION.
    CLASS-METHODS:
      start_of_selection RAISING zcx_eui_exception.
ENDCLASS.

CLASS lcl_main IMPLEMENTATION.
  METHOD start_of_selection.
    CASE abap_true.
      WHEN p_exp.
        SELECT * INTO TABLE @DATA(lt_data) "#EC CI_NOWHERE.
        FROM ztaqo_option.

        CALL TRANSFORMATION id SOURCE data = lt_data
                               RESULT XML DATA(lv_xml).

        NEW zcl_eui_file( iv_xstring = lv_xml )->download( iv_save_dialog = 'X' ).

      WHEN p_imp.
        CHECK sy-sysid = 'SB6'.
        DATA(lo_file) = NEW zcl_eui_file( )->import_from_file( ).
        CALL TRANSFORMATION id SOURCE XML lo_file->mv_xstring
                               RESULT data = lt_data.
        " DELETE FROM ztaqo_option.
        INSERT ztaqo_option FROM TABLE lt_data.
        COMMIT WORK AND WAIT.
    ENDCASE.
  ENDMETHOD.
ENDCLASS.


START-OF-SELECTION.
  TRY.
      lcl_main=>start_of_selection( ).
    CATCH zcx_eui_exception INTO DATA(lo_error).
      MESSAGE lo_error TYPE 'S' DISPLAY LIKE 'E'.
  ENDTRY.
