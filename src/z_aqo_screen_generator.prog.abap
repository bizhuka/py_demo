*&---------------------------------------------------------------------*
*&---------------------------------------------------------------------*
REPORT z_aqo_screen_generator.

DATA:
   ztaqo_option TYPE ztaqo_option.

SELECTION-SCREEN BEGIN OF BLOCK bl_main WITH FRAME.
SELECT-OPTIONS:
 s_pack FOR ztaqo_option-package_id DEFAULT '$TMP',
 s_opt  FOR ztaqo_option-option_id  DEFAULT 'Main options'.
PARAMETERS
 p_view AS CHECKBOX.
SELECTION-SCREEN END OF BLOCK bl_main.

**********************************************************************
**********************************************************************

CLASS lcl_main DEFINITION FINAL.
  PUBLIC SECTION.
    METHODS:
      start_of_selection.
ENDCLASS.

**********************************************************************
**********************************************************************

CLASS lcl_main IMPLEMENTATION.
  METHOD start_of_selection.
    SELECT package_id, option_id INTO TABLE @DATA(lt_opt)
    FROM ztaqo_option
    WHERE package_id IN @s_pack
      AND option_id  IN @s_opt.

    LOOP AT lt_opt ASSIGNING FIELD-SYMBOL(<ls_opt>).
      MESSAGE |Show { <ls_opt>-package_id } { <ls_opt>-option_id }| TYPE 'S'.
      SET PARAMETER ID: 'ZAQO_PACKAGE_ID' FIELD <ls_opt>-package_id,
                        'ZAQO_OPTION_ID'  FIELD <ls_opt>-option_id,
                        'ZAQO_COMMAND'    FIELD 'OPEN_OPTION'.
      DATA(lv_tcode) = COND sytcode( WHEN p_view = abap_true THEN 'ZAQO_VIEWER_OLD' ELSE 'ZAQO_EDITOR_OLD' ).
      CALL TRANSACTION lv_tcode AND SKIP FIRST SCREEN.   "#EC CI_CALLTA
    ENDLOOP.
  ENDMETHOD.
ENDCLASS.


**********************************************************************
**********************************************************************
INITIALIZATION.
  DATA(go_main) = NEW lcl_main( ).

START-OF-SELECTION.
  go_main->start_of_selection( ).
