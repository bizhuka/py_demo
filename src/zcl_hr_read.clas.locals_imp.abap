*"* use this source file for the definition and implementation of
*"* local helper classes, interface definitions and type
*"* declarations

CLASS lcl_regular_pay IMPLEMENTATION.
*  METHOD init.
*    FIELD-SYMBOLS  <lt_pernr> TYPE STANDARD TABLE.
*
*    " Init 1 time only
*    IF it_pernr IS NOT INITIAL.
*      ASSIGN it_pernr TO <lt_pernr>.
*    ELSE.
*      " Try do detect
*      ASSIGN ('(SAPDBPNPCE)G_CLUSTER_SELECTED_PERNRS') TO <lt_pernr>.
*      IF <lt_pernr> IS NOT ASSIGNED.
*        ASSIGN ('(SAPDBPNP)PERNR_TAB[]') TO <lt_pernr>.
*      ENDIF.
*    ENDIF.
*
*    " What?
*    IF <lt_pernr> IS NOT ASSIGNED.
*      zcx_eui_exception=>raise_dump( iv_message = |Is the '{ sy-cprog }' based on LDB ?| ).
*    ENDIF.
*
*    " New items
*    DATA lt_pernr_rgdir LIKE mt_pernr_rgdir.
*
*    " check also the order of table ?
*    lt_pernr_rgdir = CORRESPONDING #( <lt_pernr> ).
*    CHECK lt_pernr_rgdir IS NOT INITIAL.
*
*    " Find all MOLGA
*    SELECT p1~pernr, t~molga INTO TABLE @DATA(lt_p1_molga) "#EC CI_BUFFJOIN
*    FROM pa0001 AS p1 INNER JOIN t001p AS t ON t~werks = p1~werks AND t~btrtl = p1~btrtl
*    FOR ALL ENTRIES IN @lt_pernr_rgdir
*    WHERE p1~pernr =  @lt_pernr_rgdir-pernr
*      AND p1~sprps =  @space
*      AND p1~endda >= @iv_begda
*      AND p1~begda <= @iv_endda.
*
*    " set molga
*    LOOP AT lt_p1_molga ASSIGNING FIELD-SYMBOL(<ls_p1_molga>).
*      READ TABLE lt_pernr_rgdir ASSIGNING FIELD-SYMBOL(<ls_pernr_rgdir>)
*       WITH TABLE KEY pernr = <ls_p1_molga>-pernr.
*      CHECK sy-subrc = 0.
*
*      <ls_pernr_rgdir>-molga = <ls_p1_molga>-molga.
*    ENDLOOP.
*
*    " Insert new items. in a LOOP ?
*    INSERT LINES OF lt_pernr_rgdir INTO TABLE mt_pernr_rgdir.
*  ENDMETHOD.

  METHOD get_payroll.
*    DO 2 TIMES.
*      " First attempt?
*      DATA(lv_index) = sy-index.
*
*      READ TABLE mt_pernr_rgdir ASSIGNING FIELD-SYMBOL(<ls_pernr_rgdir>)
*       WITH TABLE KEY pernr = iv_pernr.
*      IF sy-subrc = 0.
*        EXIT.
*      ENDIF.
*
*      " init cache
*      IF lv_index = 1.
*        init( iv_begda = iv_begda
*              iv_endda = iv_endda
*              iv_molga = iv_molga ).
*      ENDIF.
*    ENDDO.
*
*    " Oops
*    IF <ls_pernr_rgdir> IS NOT ASSIGNED.
*      zcx_eui_exception=>raise_dump( iv_message = |Cannot detect MOLGA for '{ iv_pernr }'| ).
*    ENDIF.

    ASSIGN mt_pernr_rgdir[ pernr = iv_pernr ] TO FIELD-SYMBOL(<ls_pernr_rgdir>).
    IF SY-subrc <> 0.
      INSERT VALUE #( pernr = iv_pernr
                      molga = iv_molga ) INTO TABLE mt_pernr_rgdir ASSIGNING <ls_pernr_rgdir>.
    ENDIF.

    " Get molga
    DATA(lv_molga) = <ls_pernr_rgdir>-molga.
    CHECK lv_molga IS NOT INITIAL.

    " Return as a result
    READ TABLE mt_payroll INTO rs_payroll
     WITH TABLE KEY molga      = lv_molga
                    pay_period = iv_pay_period.
    CHECK sy-subrc <> 0.

    " Add to cache
    INSERT VALUE #( molga      = lv_molga
                    pay_period = iv_pay_period ) INTO TABLE mt_payroll ASSIGNING FIELD-SYMBOL(<ls_payroll>).

    " Use standardc class
    IF iv_std_class = abap_true.
      DATA(ls_range) = zcl_hr_month=>get_range( iv_pay_period && '01' ).
      cl_hrpay99_prr_4_pnp_reps=>get_instance(
       EXPORTING
        im_molga                = lv_molga
        im_pn_paper             = CONV #( iv_pay_period )
        im_pn_begda             = ls_range-begda
        im_pn_endda             = ls_range-endda
        im_pnpdisbd             = sy-datum  " standard didn't use this field but control non-empty value
        im_pn_permo             = iv_permo
        im_ipview               = iv_ipview
        im_add_retroes_to_rgdir = iv_add_retroes_to_rgdir
        im_arch_too             = iv_arch_too
       IMPORTING
         ex_prr     = <ls_payroll>-payroll
       EXCEPTIONS
         OTHERS     = 4 ).
    ELSE.
      " Use own cache
      CREATE OBJECT <ls_payroll>-payroll TYPE lcl_regular_pay
        EXPORTING
          im_molga                = lv_molga
          im_pabrp                = CONV #( iv_pay_period+4(2) )
          im_pabrj                = CONV #( iv_pay_period(4) )
          im_permo                = iv_permo
          im_ipview               = iv_ipview
          im_add_retroes_to_rgdir = iv_add_retroes_to_rgdir
          im_arch_too             = iv_arch_too
        EXCEPTIONS
          OTHERS                  = 4.
    ENDIF.

    " Oops
    IF sy-subrc <> 0.
      MESSAGE ID sy-msgid TYPE 'S' NUMBER sy-msgno WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4 DISPLAY LIKE 'E'.
      CLEAR <ls_payroll>-payroll.
      RETURN.
    ENDIF.

    " Cast Base class

    " regular & off-cycle run
    TRY.
        <ls_payroll>-payroll_payper ?= <ls_payroll>-payroll.
      CATCH cx_sy_move_cast_error.
        CLEAR <ls_payroll>-payroll_payper.
    ENDTRY.

    " everything within a single day
    TRY.
        <ls_payroll>-payroll_sngday ?= <ls_payroll>-payroll.
      CATCH cx_sy_move_cast_error.
        CLEAR <ls_payroll>-payroll_sngday.
    ENDTRY.

    " everything within a timespan
    TRY.
        <ls_payroll>-payroll_tispan ?= <ls_payroll>-payroll.
      CATCH cx_sy_move_cast_error.
        CLEAR <ls_payroll>-payroll_tispan.
    ENDTRY.

    " And return
    rs_payroll = <ls_payroll>.
  ENDMETHOD.

  METHOD read_rgdir_from.
    CONSTANTS lc_cache_size TYPE i VALUE 70.

    " Clear prev memory
    DATA(lv_from) = iv_tabix - lc_cache_size.
    DATA(lv_to)   = iv_tabix - 1.
    IF lv_from > 0.
      LOOP AT mt_pernr_rgdir ASSIGNING FIELD-SYMBOL(<ls_pernr_rgdir>) FROM lv_from TO lv_to.
        FREE <ls_pernr_rgdir>-rgdir.
        FREE <ls_pernr_rgdir>-loaded.
      ENDLOOP.
    ENDIF.

    DATA(lt_pernr) = VALUE zcl_hr_read=>tt_pernr( ).
    lv_from = iv_tabix.
    lv_to   = iv_tabix + lc_cache_size - 1.
    LOOP AT mt_pernr_rgdir ASSIGNING <ls_pernr_rgdir> FROM lv_from TO lv_to.
      " Set 1 time ?
      <ls_pernr_rgdir>-loaded = abap_true.

      " For mass selection
      INSERT VALUE #( pernr = <ls_pernr_rgdir>-pernr ) INTO TABLE lt_pernr.
    ENDLOOP.

    " For data selection
    CHECK lt_pernr IS NOT INITIAL.

    "Read from the transparent payroll directory in table HRPY_RGDIR
    SELECT * INTO TABLE @DATA(lt_rgdir)       "#EC CI_ALL_FIELDS_NEEDED
    FROM hrpy_rgdir
    FOR ALL ENTRIES IN @lt_pernr
    WHERE pernr = @lt_pernr-pernr
    ORDER BY PRIMARY KEY.

    DATA(lv_prev_pernr) = CONV pernr-pernr( 0 ).
    LOOP AT lt_rgdir ASSIGNING FIELD-SYMBOL(<ls_rgdir>).
      " To new item ?
      IF lv_prev_pernr <> <ls_rgdir>-pernr.
        lv_prev_pernr = <ls_rgdir>-pernr.
        READ TABLE mt_pernr_rgdir ASSIGNING <ls_pernr_rgdir>
         WITH TABLE KEY pernr = lv_prev_pernr.
      ENDIF.

      " No pernr in result
      APPEND CORRESPONDING #( <ls_rgdir> ) TO <ls_pernr_rgdir>-rgdir.
    ENDLOOP.
  ENDMETHOD.

  METHOD read_whole_rgdir.
    " Find postion in list
    READ TABLE mt_pernr_rgdir ASSIGNING FIELD-SYMBOL(<ls_pernr_rgdir>)
     WITH TABLE KEY pernr = me->a_pernr.
    DATA(lv_tabix) = sy-tabix.

    " Error in algorithm ?
    IF sy-subrc <> 0. " OR <ls_pernr_rgdir>-loaded > 1.
      super->read_whole_rgdir(
        IMPORTING
          ex_rgdir = ex_rgdir ).
      RETURN.
    ENDIF.

    " Init cache
    IF <ls_pernr_rgdir>-loaded <> abap_true.
      read_rgdir_from( lv_tabix ).
    ENDIF.

    " No need
    CLEAR ex_rgdir.
    IF me->a_pernr IS INITIAL.
      RAISE no_entries_found.
    ENDIF.

    " Already changed
    ex_rgdir = <ls_pernr_rgdir>-rgdir[].

    " No need
    IF ex_rgdir IS INITIAL.
      RAISE no_entries_found.
    ENDIF.

    CALL FUNCTION 'CU_FILTER_RGDIR_BY_AUTH'
      EXPORTING
        iv_pernr          = me->a_pernr
        iv_molga          = me->a_molga "temporary, will be removed in 20xx
      CHANGING
        ct_cluster_dir    = ex_rgdir
      EXCEPTIONS
        inconsistent_data = 1
        OTHERS            = 2.
    IF sy-subrc <> 0.
      MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4
         RAISING no_entries_found.
    ENDIF.
  ENDMETHOD.
ENDCLASS.
