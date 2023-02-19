class ZCL_HR_READ definition
  public
  final
  create private .

public section.

  types:
    BEGIN OF ts_payroll_results,
        " Base class
        payroll        TYPE REF TO cl_hrpay99_prr_4_pnp_reps,
        " regular & off-cycle run
        payroll_payper TYPE REF TO cl_hrpay99_prr_4_pnp_payper,
        " everything within a single day
        payroll_sngday TYPE REF TO cl_hrpay99_prr_4_pnp_sngday,
        " everything within a timespan
        payroll_tispan TYPE REF TO cl_hrpay99_prr_4_pnp_tispan,

        results        TYPE h99_hr_pay_result_tab,
      END OF ts_payroll_results .
  types:
    tt_payroll_results TYPE STANDARD TABLE OF ts_payroll_results WITH DEFAULT KEY .
  types:
    tt_pernr TYPE STANDARD TABLE OF hrpernr WITH DEFAULT KEY .

  class-methods PAYROLL_RESULTS
    importing
      !IV_PERNR type PERNR-PERNR
      !IV_BEGDA type BEGDA
      !IV_ENDDA type ENDDA
      !IV_PERMO type PERMO default '01'
      !IV_IPVIEW type H99_IPVIEW default ABAP_TRUE
      !IV_ADD_RETROES_TO_RGDIR type H99_ADD_RETROES default ABAP_TRUE
      !IV_ARCH_TOO type ARCH_TOO default ABAP_FALSE
      !IV_STD_CLASS type ABAP_BOOL optional
      !IV_MOLGA type MOLGA default 'KZ'
    returning
      value(RT_PAYROLL_RESULTS) type TT_PAYROLL_RESULTS .
  class-methods INFTY_ROW
    importing
      !IV_INFTY type INFTY
      !IV_PERNR type PERNR-PERNR
      !IV_BEGDA type BEGDA default '18000101'
      !IV_ENDDA type ENDDA default '99991231'
      !IV_TCLAS type PSPAR-TCLAS default 'A'
      !IV_SPRPS type SPRPS default IF_HRPA_READ_INFOTYPE=>UNLOCKED
      !IV_NO_AUTH type ABAP_BOOL default ABAP_FALSE
      value(IV_INDEX) type SYTABIX optional
      !IS_DEFAULT type ANY optional
      !IV_WHERE type CSEQUENCE optional
      !IV_PARAM1 type ANY optional
      !IV_PARAM2 type ANY optional
      !IV_PARAM3 type ANY optional
    returning
      value(RR_ROW) type ref to DATA .
  class-methods INFTY_TAB
    importing
      !IV_INFTY type INFTY
      !IV_PERNR type PERNR-PERNR
      !IV_BEGDA type BEGDA default '18000101'
      !IV_ENDDA type ENDDA default '99991231'
      !IV_TCLAS type PSPAR-TCLAS default 'A'
      !IV_SPRPS type SPRPS default IF_HRPA_READ_INFOTYPE=>UNLOCKED
      !IV_NO_AUTH type ABAP_BOOL default ABAP_FALSE
      !IV_WHERE type CSEQUENCE optional
      !IV_PARAM1 type ANY optional
      !IV_PARAM2 type ANY optional
      !IV_PARAM3 type ANY optional
    returning
      value(RR_TAB) type ref to DATA .
  class-methods INFTY_OM_ROW
    importing
      !IV_INFTY type INFTY
      !IV_OTYPE type PLOG-OTYPE
      !IV_OBJID type PLOG-OBJID
      !IV_PLVAR type PLOG-PLVAR optional
      !IV_SUBTY type SUBTY optional
      !IV_ISTAT type PLOG-ISTAT optional
      !IV_BEGDA type BEGDA default '19000101'
      !IV_ENDDA type ENDDA default '99991231'
      !IV_NO_AUTH type ABAP_BOOL default ABAP_FALSE
      value(IV_INDEX) type SYTABIX optional
      !IS_DEFAULT type ANY optional
      !IV_WHERE type CSEQUENCE optional
      !IV_PARAM1 type ANY optional
      !IV_PARAM2 type ANY optional
      !IV_PARAM3 type ANY optional
    returning
      value(RR_ROW) type ref to DATA .
  class-methods INFTY_OM_TAB
    importing
      !IV_INFTY type INFTY
      !IV_OTYPE type PLOG-OTYPE
      !IV_OBJID type PLOG-OBJID
      value(IV_PLVAR) type PLOG-PLVAR optional
      !IV_SUBTY type SUBTY optional
      !IV_ISTAT type PLOG-ISTAT optional
      !IV_BEGDA type BEGDA default '19000101'
      !IV_ENDDA type ENDDA default '99991231'
      !IV_NO_AUTH type ABAP_BOOL default ABAP_FALSE
      !IV_WHERE type CSEQUENCE optional
      !IV_PARAM1 type ANY optional
      !IV_PARAM2 type ANY optional
      !IV_PARAM3 type ANY optional
    returning
      value(RR_TAB) type ref to DATA .
  class-methods FILL_TBDAT
    importing
      !IV_INFTY type INFOTYP
      !IV_TABNR type HRTABNR
    exporting
      !ET_TBDAT type STANDARD TABLE .
protected section.
private section.
ENDCLASS.



CLASS ZCL_HR_READ IMPLEMENTATION.


  METHOD fill_tbdat.
    " Call only from LDB PCH!
    PERFORM int_get_tbdat IN PROGRAM sapdbpch " <--- PUT OBJEC also read HRT* tables
     TABLES et_tbdat
     USING  iv_infty
            iv_tabnr.
  ENDMETHOD.


METHOD infty_om_row.
  DATA(lr_table) = infty_om_tab(
    " Standard parameters
    iv_plvar   = iv_plvar
    iv_infty   = iv_infty
    iv_otype   = iv_otype
    iv_objid   = iv_objid
    iv_subty   = iv_subty
    iv_istat   = iv_istat
    iv_begda   = iv_begda
    iv_endda   = iv_endda
    iv_no_auth = iv_no_auth

    " For LOOP where
    iv_where   = iv_where
    iv_param1  = iv_param1
    iv_param2  = iv_param2
    iv_param3  = iv_param3 ).

  FIELD-SYMBOLS <lt_table> TYPE INDEX TABLE.
  ASSIGN lr_table->* TO <lt_table>.

  " Pass IV_INDEX = 1 if needed
  IF iv_index IS INITIAL.
    iv_index = lines( <lt_table> ).
  ENDIF.
  READ TABLE <lt_table> REFERENCE INTO rr_row INDEX iv_index.

  " Pass IS_DEFAULT and don't check result
  CHECK rr_row IS INITIAL AND is_default IS SUPPLIED.
  TRY.
      " Passed as NEW P1000( ) for changing afterwards ?
      rr_row ?= is_default.
    CATCH cx_sy_move_cast_error.
      " Passed as VALUE P1000( )
      rr_row = REF #( is_default ).
  ENDTRY.
ENDMETHOD.


METHOD infty_om_tab.
  DATA(lv_type) = |P{ iv_infty }|.

  DATA lr_copy TYPE REF TO data.
  CREATE DATA: rr_tab  TYPE STANDARD TABLE OF (lv_type),
               lr_copy TYPE STANDARD TABLE OF (lv_type).

  FIELD-SYMBOLS: <lt_result> TYPE STANDARD TABLE,
                 <lt_copy>   TYPE STANDARD TABLE.

  ASSIGN: rr_tab->*  TO <lt_result>,
          lr_copy->* TO <lt_copy>.

  " Skip autority checks
  IF iv_no_auth = abap_true.
    ASSIGN ('(SAPLRHAC)AUTHORITY_CHECK_ACTIVE') TO FIELD-SYMBOL(<lv_auth>).
    DATA(lv_prev_auth) = COND char1( WHEN sy-subrc = 0
                                     THEN <lv_auth>
                                     ELSE '1' " ON
                                   ).
    CALL FUNCTION 'RH_AUTHORITY_CHECK_OFF'.
  ENDIF.

  IF iv_plvar IS INITIAL.
    CALL FUNCTION 'RH_GET_ACTIVE_WF_PLVAR'
      IMPORTING
        act_plvar = iv_plvar
      EXCEPTIONS
        OTHERS    = 0.
  ENDIF.

  " Finally read
  CALL FUNCTION 'RH_READ_INFTY'
    EXPORTING
      plvar  = iv_plvar
      otype  = iv_otype
      objid  = iv_objid
      infty  = iv_infty
      subty  = iv_subty
      istat  = iv_istat
      begda  = iv_begda
      endda  = iv_endda
    TABLES
      innnn  = <lt_copy>
    EXCEPTIONS
      OTHERS = 0.

  " Restore previous value
  IF iv_no_auth = abap_true.
    ASSIGN ('(SAPLRHAC)AUTHORITY_CHECK_ACTIVE') TO <lv_auth>.
    IF <lv_auth> IS ASSIGNED.
      <lv_auth> = lv_prev_auth.
    ENDIF.
  ENDIF.

  " Add to results by condition
  LOOP AT <lt_copy> ASSIGNING FIELD-SYMBOL(<ls_copy>) WHERE (iv_where) ##NEEDED.
    APPEND <ls_copy> TO <lt_result>.
  ENDLOOP.
ENDMETHOD.


METHOD infty_row.
  DATA(lr_table) = infty_tab(
    " Standard parameters
    iv_infty   = iv_infty
    iv_pernr   = iv_pernr
    iv_begda   = iv_begda
    iv_endda   = iv_endda
    iv_tclas   = iv_tclas
    iv_sprps   = iv_sprps
    iv_no_auth = iv_no_auth

    " For LOOP where
    iv_where   = iv_where
    iv_param1  = iv_param1
    iv_param2  = iv_param2
    iv_param3  = iv_param3 ).

  FIELD-SYMBOLS <lt_table> TYPE INDEX TABLE.
  ASSIGN lr_table->* TO <lt_table>.

  " Pass IV_INDEX = 1 if needed
  IF iv_index IS INITIAL.
    iv_index = lines( <lt_table> ).
  ENDIF.
  READ TABLE <lt_table> REFERENCE INTO rr_row INDEX iv_index.

  " Pass IS_DEFAULT and don't check result
  CHECK rr_row IS INITIAL AND is_default IS SUPPLIED.
  TRY.
      " Passed as NEW P0001( ) for changing afterwards ?
      rr_row ?= is_default.
    CATCH cx_sy_move_cast_error.
      " Passed as VALUE P0001( )
      rr_row = REF #( is_default ).
  ENDTRY.
ENDMETHOD.


METHOD infty_tab.
  DATA(lv_type) = |P{ iv_infty }|.

  DATA lr_copy TYPE REF TO data.
  CREATE DATA: rr_tab  TYPE STANDARD TABLE OF (lv_type),
               lr_copy TYPE STANDARD TABLE OF (lv_type).

  FIELD-SYMBOLS: <lt_result> TYPE STANDARD TABLE,
                 <lt_copy>   TYPE STANDARD TABLE.

  ASSIGN: rr_tab->*  TO <lt_result>,
          lr_copy->* TO <lt_copy>.

  " flag cleared after every call
  IF iv_no_auth = abap_true.
    CALL FUNCTION 'HR_READ_INFOTYPE_AUTHC_DISABLE'.
  ENDIF.

  " Finally read
  CALL FUNCTION 'HR_READ_INFOTYPE'
    EXPORTING
      pernr           = iv_pernr
      infty           = iv_infty
      begda           = iv_begda
      endda           = iv_endda
      tclas           = iv_tclas
      sprps           = iv_sprps
    TABLES
      infty_tab       = <lt_copy>
    EXCEPTIONS
      OTHERS          = 2.
  CHECK sy-subrc = 0.

  " Add to results by condition
  LOOP AT <lt_copy> ASSIGNING FIELD-SYMBOL(<ls_copy>) WHERE (iv_where) ##NEEDED.
    APPEND <ls_copy> TO <lt_result>.
  ENDLOOP.
ENDMETHOD.


METHOD payroll_results.
  " YEAR + MONTH
  DATA(lv_begda_mon) = CONV faper( iv_begda(6) ).

  " Process all periods month by month
  WHILE iv_endda(6) >= lv_begda_mon.
    DATA(ls_payroll) = lcl_regular_pay=>get_payroll(
      iv_pernr                = iv_pernr
      iv_begda                = iv_begda
      iv_endda                = iv_endda
      iv_molga                = iv_molga
      iv_std_class            = iv_std_class
      iv_pay_period           = lv_begda_mon
      iv_ipview               = iv_ipview
      iv_permo                = iv_permo
      iv_add_retroes_to_rgdir = iv_add_retroes_to_rgdir
      iv_arch_too             = iv_arch_too ).

    IF ls_payroll-payroll IS NOT INITIAL.
      ls_payroll-payroll->get_pernr_payr_results_allin1(
        EXPORTING im_pernr                       = iv_pernr
        IMPORTING ex_pernr_payroll_results       = DATA(lt_pernr_pr)
        EXCEPTIONS country_version_not_available = 1
                   no_authorization              = 2
                   no_entries_found              = 3 " <--- Is it possible ?
                   read_error                    = 4
                   OTHERS                        = 5 ).
      IF sy-subrc = 0.
        " Add results
        APPEND VALUE #( payroll        = ls_payroll-payroll
                        payroll_payper = ls_payroll-payroll_payper
                        payroll_sngday = ls_payroll-payroll_sngday
                        payroll_tispan = ls_payroll-payroll_tispan
                        results = lt_pernr_pr[] ) TO rt_payroll_results.
      ENDIF.
      CLEAR lt_pernr_pr[].
    ENDIF.

    " Next month
    DATA(lv_next) = CONV d( zcl_hr_month=>get_range( lv_begda_mon && '01' )-endda + 1 ).
    lv_begda_mon = lv_next(6).
  ENDWHILE.
ENDMETHOD.
ENDCLASS.
