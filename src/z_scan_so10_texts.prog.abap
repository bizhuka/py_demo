*&---------------------------------------------------------------------*
*&---------------------------------------------------------------------*
REPORT z_scan_so10_texts.

TABLES:
  stxh.

SELECTION-SCREEN BEGIN OF BLOCK bl_main WITH FRAME.
SELECT-OPTIONS:
  s_name  FOR stxh-tdname   OBLIGATORY,
  s_id    FOR stxh-tdid     DEFAULT 'ST',
  s_langu FOR stxh-tdspras  DEFAULT sy-langu,
  s_objid FOR stxh-tdobject DEFAULT 'TEXT' NO INTERVALS NO-EXTENSION OBLIGATORY.
SELECTION-SCREEN SKIP 1.
PARAMETERS:
  p_text TYPE text255 DEFAULT 'Payment',
  p_ignc AS CHECKBOX DEFAULT 'X'.
SELECTION-SCREEN END OF BLOCK bl_main.

**********************************************************************
**********************************************************************

CLASS lcl_report DEFINITION.
  PUBLIC SECTION.
    METHODS:
      initialization,
      start_of_selection,
      on_hotspot_click FOR EVENT hotspot_click OF cl_gui_alv_grid
        IMPORTING
          sender
          e_row_id.
ENDCLASS.

CLASS lcl_report IMPLEMENTATION.
  METHOD initialization.
    s_name[] = VALUE #( ( sign = 'I' option = 'CP' low = 'Z*' ) ).
  ENDMETHOD.

  METHOD start_of_selection.
    SELECT tdobject, tdname, tdid, tdspras, CAST( ' ' AS CHAR( 132 ) ) AS line INTO TABLE @DATA(lt_stxh)
    FROM stxh
    WHERE tdobject IN @s_objid[]
      AND tdid     IN @s_id[]
      AND tdspras  IN @s_langu
      AND tdname   IN @s_name[].

    LOOP AT lt_stxh ASSIGNING FIELD-SYMBOL(<ls_stxh>).
      DATA(lt_line) = VALUE tlinetab( ).
      CALL FUNCTION 'READ_TEXT'
        EXPORTING
          id       = <ls_stxh>-tdid
          language = <ls_stxh>-tdspras
          name     = <ls_stxh>-tdname
          object   = <ls_stxh>-tdobject
        TABLES
          lines    = lt_line
        EXCEPTIONS
          OTHERS   = 8.
      CHECK sy-subrc = 0 AND lt_line[] IS NOT INITIAL.

      DATA(lv_found_line) = ||.
      LOOP AT lt_line ASSIGNING FIELD-SYMBOL(<ls_line>).
        CASE p_ignc.
          WHEN abap_true.
            FIND p_text IN <ls_line>-tdline IGNORING CASE.
          WHEN abap_false.
            FIND p_text IN <ls_line>-tdline RESPECTING CASE.
        ENDCASE.
        CHECK sy-subrc = 0.

        lv_found_line = <ls_line>-tdline.
        EXIT.
      ENDLOOP.
      <ls_stxh>-line = lv_found_line.
    ENDLOOP.

    DELETE lt_stxh WHERE line IS INITIAL.
    NEW zcl_eui_alv( ir_table       = REF #( lt_stxh )
                     it_mod_catalog = VALUE #( ( fieldname = 'LINE' coltext = 'Found text' hotspot = 'X' ) )
    )->show( io_handler = me ).
  ENDMETHOD.

  METHOD on_hotspot_click.
    FIELD-SYMBOLS <lt_alv> TYPE STANDARD TABLE.
    DATA(lr_alv) = zcl_eui_conv=>get_grid_table( sender ).
    ASSIGN lr_alv->* TO <lt_alv>.

    ASSIGN <lt_alv>[ e_row_id-index ] TO FIELD-SYMBOL(<ls_alv>).
    CHECK sy-subrc = 0.
    DATA(ls_stxh) = CORRESPONDING stxh( <ls_alv> ).

    DATA(lt_bds) = VALUE tab_bdcdata( ( program = 'SAPMSSCE'      dynpro = '1100' dynbegin = 'X' )
                                      ( fnam    = 'BDC_OKCODE'    fval   = '=SHOW' )
                                      ( fnam    = 'RSSCE-TDNAME'  fval   = ls_stxh-tdname )
                                      ( fnam    = 'RSSCE-TDID'    fval   = ls_stxh-tdid )
                                      ( fnam    = 'RSSCE-TDSPRAS' fval   = ls_stxh-tdspras ) ).
    CALL TRANSACTION 'SO10' USING lt_bds MODE 'E'.
  ENDMETHOD.
ENDCLASS.


**********************************************************************
**********************************************************************

INITIALIZATION.
  DATA(go_report) = NEW lcl_report( ).
  go_report->initialization( ).

START-OF-SELECTION.
  go_report->start_of_selection( ).
