*---------------------------------------------------------------------*
*---------------------------------------------------------------------*

CLASS lcl_report IMPLEMENTATION.
  METHOD initialization.
    " Read option " @see -> SE38 - > ZAQO_TESTER (or https://github.com/bizhuka/aqo/wiki)
    TRY.
        zcl_aqo_option=>create(
            iv_package_id = '$TMP'    " Package    "#EC NOTEXT
            iv_option_id  = 'PY_DEMO' " For report "#EC NOTEXT
            ir_data       = REF #( ms_option )
            " iv_repair     = abap_true
          ).
      CATCH zcx_aqo_exception INTO DATA(lo_error).
        MESSAGE lo_error TYPE 'S' DISPLAY LIKE 'E'.
        RETURN.
    ENDTRY.

    " Month
    pnptimed = 'M'.

    " Create button
    mo_email_handler = NEW #( me ).
  ENDMETHOD.

  METHOD pbo.
    " Could be different screens
    IF sy-dynnr <> '1000'.
      " lo_1010_screen->pbo( ) ?
      CALL FUNCTION 'ZFM_EUI_PBO'.
      RETURN.
    ENDIF.

    " Change selection screen " @see -> SE38 - > ZEUI_TEST_SCREEN_02 (or https://github.com/bizhuka/eui)
    TRY.
        DATA(lo_screen) = NEW zcl_eui_screen( iv_dynnr = '1000' ).
      CATCH zcx_eui_exception INTO DATA(lo_error).
        MESSAGE lo_error TYPE 'S' DISPLAY LIKE 'E'.
        RETURN.
    ENDTRY.

    " Set any condition by SCREEN-NAME or SCREEN-GROUP1
    lo_screen->customize( name = 'PNPTIMED'
                          input = COND #( WHEN sy-datum+6(2) > 15 THEN '0'
                                                                  ELSE '1' ) ).
    " And update screen
    lo_screen->pbo( ).
  ENDMETHOD.

  METHOD pai.
    " F8
    CHECK iv_cmd = 'ONLI'.

    " Checks for screen 1000
    DATA(lv_next) = CONV d( pn-endda + 1 ).
    IF lv_next+6(2) <> '01'.
      MESSAGE |Please set end of the month for the report '{ pn-endda DATE = ENVIRONMENT }'| TYPE 'E'.
    ENDIF.
  ENDMETHOD.

  METHOD start_of_selection.
    mo_email_handler->start_of_selection( ).

    " Set LDB variables
    " pnpbegda = pn-begda = pn-begps.
    " pnpendda = pn-endda = pn-endps.

    " Change LDB behaviour
    IF ms_option-p_locked = abap_true.
      pnp-sw-ignorelockedrecords = 'N'.
    ENDIF.

    " Create dynamic table
    DATA(lt_comp) =  CAST cl_abap_structdescr( cl_abap_typedescr=>describe_by_name( 'TS_ALV' ) )->get_components( ).

    " Add ALV sum fields
    DATA(lo_sum_field) = CAST cl_abap_datadescr( cl_abap_typedescr=>describe_by_name( 'WERTV13' ) ).
    LOOP AT ms_option-t_column_opt ASSIGNING FIELD-SYMBOL(<ls_column_opt>).
      " Add 1 time
      CHECK NOT line_exists( lt_comp[ name = <ls_column_opt>-name ] ).

      APPEND VALUE #(
       name = <ls_column_opt>-name
       type = lo_sum_field ) TO lt_comp.
    ENDLOOP.

    " And create new table
    DATA(lr_table) = cl_abap_tabledescr=>create( cl_abap_structdescr=>create( lt_comp ) ).
    CREATE DATA mr_alv TYPE HANDLE lr_table.
  ENDMETHOD.

  METHOD get_peras.
    FIELD-SYMBOLS <lt_alv> TYPE STANDARD TABLE.
    DATA(ls_alv) = VALUE ts_alv( pernr = pernr-pernr ).

    " Organizational Assignment
    LOOP AT p0001 ASSIGNING FIELD-SYMBOL(<ls_0001>) WHERE begda <= pn-endda AND endda >= pn-begda.
      ls_alv-ename = <ls_0001>-ename.
      ls_alv-werks = <ls_0001>-werks.
      ls_alv-btrtl = <ls_0001>-btrtl.
    ENDLOOP.

    " Fill other static fileds of ls_alv
    " ls_alv-sbttx = zcl_py000=>get_subtype_text( iv_infty = '0298' iv_subty = '' ). " <- Get order subtype text

**********************************************************************
    " PY part. read RT[]
    DATA(lt_results) = zcl_py000=>read_payroll_results(
      iv_pernr     = pernr-pernr
      iv_begda     = pn-begda
      iv_endda     = pn-endda

      " just for test
      iv_std_class = p_std " Use stadard class for PY
    ).

    " No data in period
    IF p_empty <> abap_true.
      CHECK lt_results[] IS NOT INITIAL.
    ENDIF.

    " If have any sum
    ASSIGN mr_alv->* TO <lt_alv>.
    APPEND INITIAL LINE TO <lt_alv> ASSIGNING FIELD-SYMBOL(<ls_alv>).
    <ls_alv> = CORRESPONDING #( ls_alv ).

    " Calc by option
    LOOP AT ms_option-t_column_opt ASSIGNING FIELD-SYMBOL(<ls_column_opt>).
      " Where to write RT-BETRG sums
      FIELD-SYMBOLS <lv_alv_betrg> TYPE wertv13. " maxbt.
      ASSIGN COMPONENT <ls_column_opt>-name OF STRUCTURE <ls_alv> TO <lv_alv_betrg>.

      " Always add to ALV sum
      LOOP AT get_filtered_rt( is_column_opt      = <ls_column_opt>
                               it_payroll_results = lt_results ) ASSIGNING FIELD-SYMBOL(<ls_rt>).
        ADD <ls_rt>-betrg TO <lv_alv_betrg>.
      ENDLOOP.
    ENDLOOP. " t_column_opt option
  ENDMETHOD.

  METHOD get_filtered_rt.
    LOOP AT it_payroll_results ASSIGNING FIELD-SYMBOL(<ls_payroll_result>).
      "№0 - Info
      DATA(ls_rt) = VALUE ts_rt(
        a_payper = <ls_payroll_result>-payroll_payper->a_payper
        a_payty  = <ls_payroll_result>-payroll_payper->a_payty
      ).

      " RGDIR_COND         <--- If you want to SKIP RGDIR item
      " period-srtza = 'A' <--- For eaxample
      " Cast results to CL_HR_PAY_RESULT_XX (Where XX your MOLGA)
      LOOP AT <ls_payroll_result>-results INTO DATA(lo_result) WHERE (is_column_opt-rgdir_cond).
        "№1 - Info
        MOVE-CORRESPONDING lo_result->period TO ls_rt.

        " Process RT
        LOOP AT lo_result->inter-rt[] ASSIGNING FIELD-SYMBOL(<ls_rt>).
          " '+' or '-'
          DATA(lv_sign) = abap_undefined.

          " +
          IF <ls_rt>-lgart IN is_column_opt-t_lgart_plus[] AND is_column_opt-t_lgart_plus[] IS NOT INITIAL.
            lv_sign = abap_true.
          ENDIF.

          " -
          IF <ls_rt>-lgart IN is_column_opt-t_lgart_minus[] AND is_column_opt-t_lgart_minus[] IS NOT INITIAL.
            lv_sign = abap_false.
          ENDIF.

          " Just skip sum
          CHECK lv_sign <> abap_undefined.

          "№2 - Info Yes add to result
          MOVE-CORRESPONDING <ls_rt> TO ls_rt.
          INSERT ls_rt INTO TABLE rt_rt ASSIGNING FIELD-SYMBOL(<ls_result_rt>).

          " inverse sign
          IF lo_result->period-srtza = 'P'.
            lv_sign = xsdbool( lv_sign <> abap_true ).
          ENDIF.

          " Add or subtract
          IF lv_sign <> abap_true.
            <ls_result_rt>-betrg = - <ls_result_rt>-betrg.
          ENDIF.
        ENDLOOP. " inter-rt[]
      ENDLOOP. " PY result
    ENDLOOP.
  ENDMETHOD.

  METHOD end_of_selection.
    FIELD-SYMBOLS <lt_alv> TYPE STANDARD TABLE.

    " Oops
    ASSIGN mr_alv->* TO <lt_alv>.
    IF <lt_alv> IS INITIAL.
      MESSAGE |No data selected| TYPE 'S' DISPLAY LIKE 'E'.
      RETURN.
    ENDIF.

    " Do not show ALV
    IF sy-batch = abap_true.
      do_download( iv_send_email = abap_true ).
      RETURN.
    ENDIF.

*    " General HR report logging
*    zcl_report_logger=>log_execution( im_module = 'HR-PY' im_table  = <lt_alv>  ).

**********************************************************************
    " Modify field catalog
    DATA(lt_catalog) = VALUE lvc_t_fcat(
      ( fieldname = 'PERNR'
        hotspot   = abap_true ) ).

    " Drill down to sum
    LOOP AT ms_option-t_column_opt ASSIGNING FIELD-SYMBOL(<ls_column_opt>).
      APPEND VALUE #( fieldname = <ls_column_opt>-name
                      coltext   = <ls_column_opt>-text
                      hotspot   = abap_true
                      do_sum    = abap_true ) TO lt_catalog.
    ENDLOOP.

    " create ALV " @see -> SE38 - > ZEUI_TEST_ALV (or https://github.com/bizhuka/eui)
    NEW zcl_eui_alv(
        ir_table    = mr_alv

        is_layout   = VALUE lvc_s_layo(
           grid_title = |Period from { pn-begda DATE = ENVIRONMENT } to { pn-endda DATE = ENVIRONMENT }|
           smalltitle = abap_true
           " edit       = abap_true " <- data editing
        )

        it_toolbar = VALUE ttb_button(
        ( function = mc_cmd-group_by_main
           icon     = icon_relationship
           text     = |Group by Pers.area| )

         ( function = mc_cmd-download
           icon     = icon_xls
           text     = |Report| ) )

        " Loop and modify   LVC_T_FCAT
        it_mod_catalog = lt_catalog

        " Default handle = '0100'
        is_variant = VALUE disvariant( report = sy-cprog variant = p_layout )

      " Set PF-STATUS & Set TITLEBAR ( by default get TITLE from sy-cprog )
      )->set_status( VALUE #( title = |Demo PY program - result| )

      " And show
      )->show( io_handler      = me
               iv_handlers_map = 'ON_HOTSPOT_CLICK;ON_USER_COMMAND'  ). " <- Optional (by default all handlers)
  ENDMETHOD.

  METHOD on_hotspot_click.
    " current ALV table
    FIELD-SYMBOLS <lt_alv> TYPE STANDARD TABLE.
    ASSIGN mr_alv->* TO <lt_alv>.

    " selected row
    ASSIGN <lt_alv>[ e_row_id-index ] TO FIELD-SYMBOL(<ls_alv>).
    CHECK sy-subrc = 0.

    " Get current Personnel Number
    DATA(ls_alv) = CORRESPONDING ts_alv( <ls_alv> ).

    " tr. PA20
    IF e_column_id-fieldname = 'PERNR'.
      zcl_py000=>pa_drilldown( iv_pernr = ls_alv-pernr
                               iv_infty = '0001' ).
      RETURN.
    ENDIF.

    " Get results
    DATA(lt_results) = zcl_py000=>read_payroll_results(
      iv_pernr     = ls_alv-pernr
      iv_begda     = pn-begda
      iv_endda     = pn-endda
      iv_std_class = p_std ).

    " Drilldown to sum
    LOOP AT ms_option-t_column_opt ASSIGNING FIELD-SYMBOL(<ls_column_opt>) WHERE name = e_column_id-fieldname.
      " Get RT items
      DATA(lt_rt) = get_filtered_rt( is_column_opt      = <ls_column_opt>
                                     it_payroll_results = lt_results ).

      DATA(lt_lgart_all) = VALUE tr_lgart( ).
      APPEND LINES OF:
       <ls_column_opt>-t_lgart_plus  TO lt_lgart_all,
       <ls_column_opt>-t_lgart_minus TO lt_lgart_all.

      " Convert to range filter
      DATA(lt_filter) = VALUE lvc_t_filt(
       FOR <ls_item> IN lt_lgart_all
       ( fieldname = 'LGART'
         sign      = <ls_item>-sign
         option    = <ls_item>-option
         low       = <ls_item>-low
         high      = <ls_item>-high ) ).

      " Create new ALV
      NEW zcl_eui_alv(
       ir_table       = REF #( lt_rt )

       it_filter      = lt_filter

       it_mod_catalog = VALUE lvc_t_fcat( ( fieldname = 'BETRG' col_pos = 8 do_sum = abap_true ) )

       is_layout      = VALUE lvc_s_layo(
          grid_title = |{ ls_alv-pernr } - { <ls_column_opt>-name } ({ <ls_column_opt>-text })|
          smalltitle = abap_true )

        it_toolbar = VALUE ttb_button(
        ( function = mc_cmd-group_by_rt
           icon     = icon_relationship
           text     = |Group by LGART| ) )

      )->popup(   " As popup
      )->show( io_handler      = me
               iv_handlers_map = 'ON_USER_COMMAND' ).
    ENDLOOP.
  ENDMETHOD.

  METHOD on_user_command.
    CASE e_ucomm.
        " Export to Excel
      WHEN mc_cmd-download.
        do_download( ).

        " Change data grouping
      WHEN OTHERS.
        CHECK e_ucomm CP 'GROUP_BY_*'.

        sender->get_sort_criteria(
         IMPORTING
           et_sort = DATA(lt_sort) ).

        " Set sorting ?
        IF lt_sort IS NOT INITIAL.
          CLEAR lt_sort.
        ELSE.
          SPLIT e_ucomm+9 AT '-' INTO TABLE DATA(lt_field).
          LOOP AT lt_field ASSIGNING FIELD-SYMBOL(<lv_field>).
            APPEND VALUE #( fieldname = <lv_field> subtot = abap_true expa = abap_true ) TO lt_sort.
          ENDLOOP.
        ENDIF.

        " Set & refresh
        sender->set_sort_criteria( lt_sort ).
        sender->refresh_table_display( ).
    ENDCASE.
  ENDMETHOD.

  METHOD do_download.
    " Excel class " @see -> SE38 - > Z_XTT_INDEX (or https://github.com/bizhuka/xtt/wiki)
    DATA(lo_xtt) = NEW zcl_xtt_excel_xlsx(
      " For many templates use --->  NEW zcl_xtt_file_oaor( iv_classname  =  iv_object_key = iv_filename = )
      io_file = NEW zcl_xtt_file_smw0( 'ZR_PY000_REPORT.XLSX' ) ).

    " Create dynamic columns
    DATA(lt_column) = VALUE tt_column( ).
    LOOP AT ms_option-t_column_opt ASSIGNING FIELD-SYMBOL(<ls_column_opt>).
      " Add 1 time
      CHECK NOT line_exists( lt_column[ name = <ls_column_opt>-name ] ).

      APPEND VALUE #(
       name     = <ls_column_opt>-name
       label    = <ls_column_opt>-text
       col_name = `{R-T-` && <ls_column_opt>-name  && `;func=SUM}` ) TO lt_column.
    ENDLOOP.

    " Insert columns first
    lo_xtt->merge( iv_block_name = 'C'
                   is_block      = VALUE ts_merge0( a = lt_column )

         )->merge( iv_block_name = 'R'
                   is_block      = VALUE ts_report(
                                      " Info about period   " TODO fill scr_info
                                      begda = pn-begda
                                      endda = pn-begda

                                      " as a tree in 1-st sheet, for pivot table @see 3-d sheet
                                      t     = mr_alv ) ).

    " Do not show file
    IF iv_send_email = abap_true.
      mo_email_handler->send_to_users( lo_xtt ).
      RETURN.
    ENDIF.

    " Download or show?
    IF p_show = abap_true.
      lo_xtt->show( ).
      RETURN.
    ENDIF.
    lo_xtt->download( ).
  ENDMETHOD.

ENDCLASS.
