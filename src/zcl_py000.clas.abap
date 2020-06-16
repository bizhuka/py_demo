class ZCL_PY000 definition
  public
  final
  create public .

public section.
  type-pools ABAP .

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
    BEGIN OF ts_date_period,
        begda TYPE d,
        endda TYPE d,
      END OF ts_date_period .
  types:
    tt_pernr TYPE STANDARD TABLE OF hrpernr WITH DEFAULT KEY .

  class-methods READ_INFTY
    importing
      !IV_PERNR type PERNR-PERNR
      !IV_BEGDA type BEGDA default '18000101'
      !IV_ENDDA type ENDDA default '99991231'
      !IV_WHERE type CSEQUENCE optional
      !IT_RANGE type STANDARD TABLE optional
      !IT_RANGE2 type STANDARD TABLE optional
      !IT_RANGE3 type STANDARD TABLE optional
      !IV_SPRPS type SPRPS default IF_HRPA_READ_INFOTYPE=>UNLOCKED
      !IV_SKIP_AUTH type ABAP_BOOL default ABAP_FALSE
    exporting
      !ET_INFTY type STANDARD TABLE
      !ES_INFTY type ANY .
  class-methods READ_PAYROLL_RESULTS
    importing
      !IV_PERNR type PERNR-PERNR
      !IV_BEGDA type BEGDA
      !IV_ENDDA type ENDDA
      !IV_PERMO type PERMO default '01'
      !IV_IPVIEW type H99_IPVIEW default ABAP_TRUE
      !IV_ADD_RETROES_TO_RGDIR type H99_ADD_RETROES default ABAP_TRUE
      !IV_ARCH_TOO type ARCH_TOO default ABAP_FALSE
      !IV_STD_CLASS type ABAP_BOOL optional
      !IT_PERNR type ZCL_PY000=>TT_PERNR optional
    returning
      value(RT_PAYROLL_RESULTS) type TT_PAYROLL_RESULTS .
  class-methods GET_WITH_MONTH_END
    importing
      !IV_FROM type BEGDA
    returning
      value(RS_DATE_PERIOD) type TS_DATE_PERIOD .
  class-methods F4_LAYOUTS
    importing
      !IV_REPORT type SALV_S_LAYOUT_KEY-REPORT default SY-CPROG
      !IV_HANDLE type SALV_S_LAYOUT_KEY-HANDLE default '0100'
    changing
      !CV_LAYOUT type SLIS_VARI .
  class-methods GET_SUBTYPE_TEXT
    importing
      !IV_INFTY type INFTY
      !IV_SUBTY type SUBTY
      !IV_MOLGA type MOLGA
    returning
      value(RV_SBTTX) type SBTTX .
  class-methods PA_DRILLDOWN
    importing
      !IV_PERNR type PERNR-PERNR
      !IV_INFTY type INFTY
      !IV_SUBTY type SUBTY optional
      !IV_EDIT type ABAP_BOOL default ABAP_FALSE .
protected section.
private section.
ENDCLASS.



CLASS ZCL_PY000 IMPLEMENTATION.


METHOD f4_layouts.
  DATA(ls_layout) = cl_salv_layout_service=>f4_layouts(
    s_key    = VALUE salv_s_layout_key( report = iv_report
                                        handle = iv_handle )
    restrict = if_salv_c_layout=>restrict_none  ).

  " If ok
  CHECK ls_layout-layout IS NOT INITIAL.
  cv_layout = ls_layout-layout.
ENDMETHOD.


METHOD get_subtype_text.
  CALL FUNCTION 'HR_GET_SUBTYPE_TEXT'
    EXPORTING
      infty  = iv_infty
      subty  = iv_subty
      molga  = iv_molga
    IMPORTING
      stext  = rv_sbttx
    EXCEPTIONS
      OTHERS = 4.

  CHECK sy-subrc <> 0.
  CLEAR rv_sbttx.
ENDMETHOD.


METHOD get_with_month_end.
  " Set start date
  rs_date_period-begda = iv_from. "+0(6).

  " End of month
  rs_date_period-endda = rs_date_period-begda + 32.
  rs_date_period-endda = rs_date_period-endda+0(6) && '01'.
  rs_date_period-endda = rs_date_period-endda - 1.
ENDMETHOD.


METHOD pa_drilldown.
  " Drildown to tr. PA30 or PA20
  CALL FUNCTION 'HR_MASTERDATA_DIALOG'
    EXPORTING
      p_pernr          = iv_pernr
      p_infty          = iv_infty
      p_subty          = iv_subty
      p_activity       = COND hrbc_pernr-activity(
                                  WHEN iv_edit = abap_true THEN 'MOD'
                                                           ELSE 'DIS' )
      p_skip           = abap_true
    EXCEPTIONS
      wrong_activity   = 1
      no_authorization = 2
      OTHERS           = 3.

  " Show erros
  CHECK sy-subrc <> 0.
  MESSAGE ID sy-msgid TYPE 'S' NUMBER sy-msgno WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4 DISPLAY LIKE 'E'.
ENDMETHOD.


METHOD read_infty.
  DATA:
   lr_data   TYPE REF TO data.
  FIELD-SYMBOLS:
    <lt_result> TYPE STANDARD TABLE,
    <lt_copy>   TYPE STANDARD TABLE.

  CLEAR:
   et_infty,
   es_infty.

  " Detect data structure
  TRY.
      IF es_infty IS REQUESTED.
        DATA(lo_struc) = CAST cl_abap_structdescr( cl_abap_typedescr=>describe_by_data( es_infty ) ).
      ELSEIF et_infty IS REQUESTED.
        DATA(lo_table) = CAST cl_abap_tabledescr( cl_abap_typedescr=>describe_by_data( et_infty ) ).
        lo_struc ?= lo_table->get_table_line_type( ).
      ENDIF.
    CATCH cx_sy_move_cast_error INTO DATA(lo_err).
      zcx_eui_exception=>raise_dump( io_error = lo_err ).
  ENDTRY.

  " №1 - Check
  IF lo_struc IS INITIAL.
    zcx_eui_exception=>raise_dump( iv_message = |Pass ET_INFTY or ES_INFTY parameter!| ).
  ENDIF.

  " №2 - Check
  DATA(lv_type)  = lo_struc->get_relative_name( ).
  IF strlen( lv_type ) <> 5 OR lv_type(1) <> 'P'.
    zcx_eui_exception=>raise_dump( iv_message = |ET_INFTY or ES_INFTY are not infotype!| ).
  ENDIF.

  " Detect INFTY
  DATA(lv_infty) = CONV infty( lv_type+1 ).

  IF et_infty IS REQUESTED.
    lr_data = REF #( et_infty ).
  ELSE.
    CREATE DATA lr_data TYPE STANDARD TABLE OF (lv_type).
  ENDIF.

  " Result table
  ASSIGN lr_data->* TO <lt_result>.

  " Copy
  CREATE DATA lr_data LIKE <lt_result>.
  ASSIGN lr_data->* TO <lt_copy>.

  " Skip AUTHORITY-CHECKs
  IF iv_skip_auth = abap_true.
    " flag cleared after every call
    CALL FUNCTION 'HR_READ_INFOTYPE_AUTHC_DISABLE'.
  ENDIF.

  " Just read current
  CALL FUNCTION 'HR_READ_INFOTYPE'
    EXPORTING
      pernr           = iv_pernr
      infty           = lv_infty
      begda           = iv_begda
      endda           = iv_endda
      sprps           = iv_sprps
    TABLES
      infty_tab       = <lt_copy>
    EXCEPTIONS
      infty_not_found = 1
      OTHERS          = 2.
  CHECK sy-subrc = 0.

  " Read last by condition
  LOOP AT <lt_copy> ASSIGNING FIELD-SYMBOL(<ls_infty>) WHERE (iv_where) ##NEEDED.
    " Add to results
    APPEND <ls_infty> TO <lt_result>.
    es_infty = <ls_infty>.
  ENDLOOP.
ENDMETHOD.


METHOD read_payroll_results.
  " YEAR + MONTH
  DATA(lv_begda_mon) = CONV faper( iv_begda(6) ).

  " Process all periods month by month
  WHILE iv_endda(6) >= lv_begda_mon.
    DATA(ls_payroll) = lcl_regular_pay=>get_payroll(
      iv_pernr                = iv_pernr
      iv_begda                = iv_begda
      iv_endda                = iv_endda
      it_pernr                = it_pernr
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
    DATA(lv_next) = CONV d( get_with_month_end( lv_begda_mon && '01' )-endda + 1 ).
    lv_begda_mon = lv_next(6).
  ENDWHILE.
ENDMETHOD.
ENDCLASS.
