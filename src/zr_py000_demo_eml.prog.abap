*&---------------------------------------------------------------------*
*&---------------------------------------------------------------------*

CLASS lcl_email_handler IMPLEMENTATION.
  METHOD constructor.
    me->mo_report = io_report.

    " New GOS like button  " @see -> SE38 - > ZEUI_TEST_MENU (or https://github.com/bizhuka/eui)
    mo_menu = NEW zcl_eui_menu(
      io_handler = me ). " <- handler is ON_GOS_MENU_CLICKED

    " Create new buttons
    mo_menu->create_toolbar(
     iv_width = 90

     it_menu  = VALUE #(
      ( function = mo_report->mc_cmd-email
        text     = |E-mail|
        icon     = icon_mail ) ) ).
  ENDMETHOD.

  METHOD start_of_selection.
    " Hide button
    IF sy-batch <> abap_true.
      mo_menu->get_container( )->set_visible( abap_false ).
    ENDIF.

    " debug report in batch mode
    CHECK sy-uname IN mo_report->ms_option-t_debug_usr[] AND mo_report->ms_option-t_debug_usr[] IS NOT INITIAL.

    " tr. SM50 by menu Administration -> Program -> Debugging
    WHILE sy-batch = abap_true.
      sy-index = sy-index ##NEEDED " debug from here
      .
    ENDWHILE.
  ENDMETHOD.

  METHOD on_gos_menu_clicked.
    CHECK fcode = mo_report->mc_cmd-email.

    TRY.
        DATA(lo_screen) = NEW zcl_eui_screen(
          iv_dynnr        = '1010'

          " Actual only for global ZCL_* classes where you cannot acsess P_UNAME directly!
          ir_context      = NEW ts_context( p_uname = 'FFF' ) ).

        " Title & status is fixed (not changable in ON_PBO_EVENT)
        lo_screen->set_status( VALUE #( title = |Please change SAP login to yours!| ) ).
      CATCH zcx_eui_exception INTO DATA(lo_err).
        MESSAGE lo_err TYPE 'S' DISPLAY LIKE 'E'.
        RETURN.
    ENDTRY.

    " Make gray @see include ZR_PY000_DEMO_SSC  (commented for PAI)
    lo_screen->customize( group1 = 'GRY' input = COND #( WHEN sy-uname = 'BOSS' THEN '1'
                                                                                ELSE '0' ) ).

    " TOOD Change label (easier in Goto-> Text elements )
    " lo_screen->customize( iv_fieldname = 'P_UNAME' iv_label = 'Set only your ID' ).

    " As popup
    lo_screen->get_dimension( IMPORTING ev_col_end = DATA(lv_col_end) ).
    lo_screen->popup( iv_col_end = lv_col_end ).

    " Show dialog
    lo_screen->show( io_handler      = me
                     iv_handlers_map = 'ON_PAI_EVENT' ). " <--- Optional. By default process all handlers
  ENDMETHOD.

*  " No need
*  METHOD on_pbo_event.
*  ENDMETHOD.

  METHOD on_pai_event.
    " No need to process cancel button
    CHECK iv_command = 'OK'.

    " Who send event ?
    DATA(lo_screen) = CAST zcl_eui_screen( sender ).
    DATA(ls_context) = CAST ts_context( lo_screen->get_context( ) ).

    " if in global ZCL_* class you cannot access --->  P_UNAME or P_CHG_ID
    IF ls_context->p_uname <> sy-uname AND ls_context->p_chg_id <> abap_true.
      MESSAGE |Change login id to yours { sy-uname }| TYPE 'S' DISPLAY LIKE 'E'.
      cv_close->* = abap_false. " Do not close 1010 screen
      RETURN.
    ENDIF.

**********************************************************************
    DATA  lv_name TYPE tbtcjob-jobname VALUE sy-repid.
    DATA  lv_num  TYPE tbtcjob-jobcount.

    " @see SM37
    CALL FUNCTION 'JOB_OPEN'
      EXPORTING
        jobname  = lv_name
      IMPORTING
        jobcount = lv_num
      EXCEPTIONS
        OTHERS   = 4.
    IF sy-subrc <> 0.
      MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
      RETURN.
    ENDIF.

    " Start PNPCE report
    SUBMIT zr_py000_demo
        WITH pnppernr IN pnppernr[]
        WITH pnptimed = pnptimed
        WITH p_uname  = ls_context->p_uname
         VIA JOB lv_name NUMBER lv_num AND RETURN.

    CALL FUNCTION 'JOB_CLOSE'
      EXPORTING
        jobcount  = lv_num
        jobname   = lv_name
        strtimmed = abap_true
      EXCEPTIONS
        OTHERS    = 8.
    IF sy-subrc <> 0.
      MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
      RETURN.
    ENDIF.

    MESSAGE |Please wait finish of { lv_name } backgroud execution!| TYPE 'S'.
  ENDMETHOD.

  METHOD send_to_users.
    TYPES:
      BEGIN OF ts_report,
        uname TYPE string,
        sysid TYPE sysysid,
      END OF ts_report.

    TRY.
        DATA(lt_recipient) = VALUE zcl_xtt=>tt_recipients_bcs( ).

        " send to SAP internal email
        IF p_uname IS NOT INITIAL.
          APPEND VALUE #( recipient  = cl_sapuser_bcs=>create( p_uname )
                          express    = abap_true
                          no_forward = abap_true ) TO lt_recipient.
        ENDIF.

        " From ...
        DATA(lo_sender) = cl_cam_address_bcs=>create_internet_address( |sap@sap.com| ).

      CATCH cx_address_bcs INTO DATA(lo_err).
        MESSAGE lo_err TYPE 'S' DISPLAY LIKE 'E'.
        RETURN.
    ENDTRY.
    CHECK lt_recipient IS NOT INITIAL.

    " e-mail text is also a report
    DATA(lo_body) = NEW zcl_xtt_html(
     io_file          = NEW zcl_xtt_file_raw( iv_name   = 'dummy.html' "#EC NOTEXT
                                              iv_string = mo_report->ms_option-body ) ). " <-- from option ZPY_002-EMAIL

    " fill document structure
    lo_body->merge( VALUE ts_report(
      uname = get_full_name( sy-uname )
      sysid = sy-sysid
    ) ).

    " Ready email body
    DATA(lv_text) = zcl_eui_conv=>xstring_to_string( lo_body->get_raw( ) ).

    io_xtt->send(
     it_recipients_bcs = lt_recipient
     iv_subject        = mo_report->ms_option-subject
     iv_body           = lv_text
     io_sender         = lo_sender ).
  ENDMETHOD.

  METHOD get_full_name.
    " Login info
    SELECT SINGLE name_textc INTO rv_full_name
    FROM user_addr
    WHERE bname = iv_uname ##WARN_OK  " backward compatibility
    .
  ENDMETHOD.
ENDCLASS.
