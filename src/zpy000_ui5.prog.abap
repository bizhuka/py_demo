*&---------------------------------------------------------------------*
*&---------------------------------------------------------------------*
REPORT zpy000_ui5.

CLASS lcl_main DEFINITION FINAL.
  PUBLIC SECTION.
    METHODS:
      start_of_selection.
ENDCLASS.

CLASS lcl_main IMPLEMENTATION.
  METHOD start_of_selection.
    cl_http_ext_webapp=>create_url_for_bsp_application(
     EXPORTING bsp_application      = '/sap/zpy000/webapp/index.html'
               bsp_start_page       = ''
               bsp_start_parameters = VALUE #( "( name = 'uname'      value = sy-uname )
                                               ( name = 'sap-client' value = sy-mandt )  )
     IMPORTING abs_url              = DATA(lv_url) ).

    " Call the BSP Application in the default Browser
    CALL FUNCTION 'CALL_BROWSER'
      EXPORTING
        url         = CONV text1000( lv_url )
        window_name = 'BSP'
        new_window  = abap_true
      EXCEPTIONS
        OTHERS      = 6.

    CHECK sy-subrc <> 0.
    MESSAGE ID sy-msgid TYPE 'S' NUMBER sy-msgno WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4 DISPLAY LIKE 'E'.
  ENDMETHOD.
ENDCLASS.

**********************************************************************

INITIALIZATION.
  DATA(lo_main) = NEW lcl_main( ).

START-OF-SELECTION.
  lo_main->start_of_selection( ).
