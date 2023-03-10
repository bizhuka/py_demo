CLASS zcl_py000_avatar DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC .

  PUBLIC SECTION.

    INTERFACES: zif_sadl_exit,
      zif_sadl_stream_runtime.

    METHODS:
      get_employee_photo IMPORTING iv_pernr        TYPE pernr-pernr
                                   iv_size         TYPE i OPTIONAL
                         RETURNING VALUE(rv_photo) TYPE xstring.


  PROTECTED SECTION.
  PRIVATE SECTION.
    METHODS:
      _change_image_size IMPORTING iv_photo       TYPE xstring
                                   iv_size        TYPE i
                         RETURNING VALUE(rv_icon) TYPE xstring.
ENDCLASS.



CLASS ZCL_PY000_AVATAR IMPLEMENTATION.


  METHOD get_employee_photo.
    DATA lt_connection TYPE STANDARD TABLE OF bdn_con.
    CALL FUNCTION 'BDS_ALL_CONNECTIONS_GET'
      EXPORTING
        classname       = 'PREL'
        classtype       = 'CL'
        objkey          = CONV swotobjid-objkey( iv_pernr && '%' )
      TABLES
        all_connections = lt_connection
      EXCEPTIONS
        OTHERS          = 0.
    LOOP AT lt_connection ASSIGNING FIELD-SYMBOL(<ls_connection>) WHERE doc_type EQ 'HRICOLFOTO' OR doc_type EQ 'HRIEMPFOTO'.
      DATA(lt_info) = VALUE ilm_stor_t_scms_acinf( ).
      DATA(lt_bin)  = VALUE btc_t_xmlxtab( ).
      CLEAR: lt_info, lt_bin.
      CALL FUNCTION 'SCMS_DOC_READ'
        EXPORTING
          stor_cat    = space
          crep_id     = <ls_connection>-contrep
          doc_id      = <ls_connection>-bds_docid
        TABLES
          access_info = lt_info
          content_bin = lt_bin
        EXCEPTIONS
          OTHERS      = 15.
      CHECK sy-subrc = 0 AND lt_info[] IS NOT INITIAL AND lt_bin IS NOT INITIAL.

      rv_photo = zcl_eui_conv=>binary_to_xstring( it_table  = lt_bin
                                                  iv_length = lt_info[ 1 ]-comp_size ).
      IF iv_size IS NOT INITIAL.
        rv_photo = _change_image_size( iv_photo = rv_photo
                                       iv_size  = iv_size ).
      ENDIF.
      RETURN.
    ENDLOOP.
  ENDMETHOD.


  METHOD zif_sadl_stream_runtime~create_stream.
  ENDMETHOD.


  METHOD zif_sadl_stream_runtime~get_stream.
    DATA(ls_item) = VALUE zdpy000_avatar(
      pernr = it_key_tab[ name = 'pernr' ]-value
    ).
    ASSIGN it_filter[ property = 'IMG_SIZE' ] TO FIELD-SYMBOL(<ls_img_filter>).
    IF sy-subrc = 0.
      ls_item-img_size = VALUE #( <ls_img_filter>-select_options[ 1 ]-low OPTIONAL ).
    ENDIF.

    LOOP AT it_key_tab ASSIGNING FIELD-SYMBOL(<ls_key>).
      ASSIGN COMPONENT <ls_key>-name OF STRUCTURE ls_item TO FIELD-SYMBOL(<lv_value>).
      CHECK sy-subrc = 0.
      <lv_value> = <ls_key>-value.
    ENDLOOP.

    DATA(lv_content)   = get_employee_photo( iv_pernr = ls_item-pernr
                                             iv_size  = ls_item-img_size ).
    IF lv_content IS INITIAL.
      lv_content = cl_http_utility=>decode_x_base64( 'Qk06AAAAAAAAADYAAAAoAAAAAQAAAAEAAAABABgAAAAAAAQAAADEDgAAxA4AAAAAAAAAAAAA////AA==' ).
    ENDIF.

    DATA(lv_mime_type) = |image/jpeg|.
    io_srv_runtime->set_header(
         VALUE #( name  = 'Content-Disposition'
                  value = |inline; filename="ok.jpg"| ) ).

    " Any binary file
    er_stream = NEW /iwbep/cl_mgw_abs_data=>ty_s_media_resource(
      value     = lv_content
      mime_type = lv_mime_type ).
  ENDMETHOD.


  METHOD _change_image_size.
    CHECK iv_photo IS NOT INITIAL.
    DATA(o_ip) = NEW cl_fxs_image_processor( ).
    DATA(lv_hndl) = o_ip->add_image( iv_data = iv_photo ).

    o_ip->get_info( EXPORTING
                      iv_handle   = lv_hndl
                    IMPORTING
*                      ev_mimetype = DATA(lv_mimetype)
                      ev_xres     = DATA(lv_xres)
                      ev_yres     = DATA(lv_yres)
*                      ev_xdpi     = DATA(lv_xdpi)
*                      ev_ydpi     = DATA(lv_ydpi)
*                      ev_bitdepth = DATA(lv_bitdepth)
                      ).

    o_ip->resize(  iv_handle = lv_hndl
                   iv_xres   = iv_size
                   iv_yres   = iv_size / lv_xres * lv_yres ).

    o_ip->convert( iv_handle = lv_hndl
                   iv_format = cl_fxs_mime_types=>co_image_jpeg ).
*    CHECK sy-subrc = 0.

    rv_icon = o_ip->get_image( lv_hndl ).
  ENDMETHOD.
ENDCLASS.
