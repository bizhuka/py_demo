CLASS zcl_py000_report_rt DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC .

  PUBLIC SECTION.

    INTERFACES zif_sadl_exit.
    INTERFACES zif_sadl_read_runtime.

    METHODS: read_py IMPORTING iv_pernr TYPE PERNR-pernr
                               iv_date  TYPE d,

             get_rt_sum_info IMPORTING iv_field_name TYPE csequence
                                       iv_pos        TYPE i OPTIONAL
                             EXPORTING ev_sum        TYPE numeric
                                       et_detail     TYPE STANDARD TABLE.
  PROTECTED SECTION.
  PRIVATE SECTION.
    DATA:
      mt_py_results TYPE zcl_hr_read=>TT_PAYROLL_RESULTS.
ENDCLASS.



CLASS ZCL_PY000_REPORT_RT IMPLEMENTATION.


 METHOD get_rt_sum_info.
   CLEAR: ev_sum,
          et_detail.

    LOOP AT mt_py_results ASSIGNING FIELD-SYMBOL(<ls_py_result>).
      DATA(ls_alv)    = VALUE zc_py000_report_rt(
         pernr    = <ls_py_result>-payroll_payper->a_pernr
         key_date = <ls_py_result>-payroll_payper->a_payper && '01'
         faper    = <ls_py_result>-payroll_payper->a_payper
         payty    = <ls_py_result>-payroll_payper->a_payty ).

      LOOP AT <ls_py_result>-results INTO DATA(lo_result). " WHERE
        MOVE-CORRESPONDING lo_result->period TO ls_alv.

        LOOP AT lo_result->inter-rt ASSIGNING FIELD-SYMBOL(<ls_rt>).
          CASE iv_field_name.
            WHEN 'SUM_1'.
              CHECK <ls_rt>-lgart CP '1*'.
            WHEN 'SUM_2'.
              CHECK <ls_rt>-lgart CP '2*'.
            WHEN OTHERS.
              RETURN.
          ENDCASE.

          MOVE-CORRESPONDING <ls_rt> TO ls_alv.

          ls_alv-pos = ls_alv-pos + 1.
          IF iv_pos IS NOT INITIAL.
            CHECK iv_pos = ls_alv-pos.
          ENDIF.

          " Results
          ev_sum = ev_sum + <ls_rt>-betrg.
          CHECK et_detail IS REQUESTED.
          APPEND ls_alv TO et_detail.
        ENDLOOP.
      ENDLOOP.
    ENDLOOP.
 ENDMETHOD.


 METHOD read_py.
    DATA(ls_range) = zcl_hr_month=>get_range( iv_date(6) && '01' ).
    mt_py_results = zcl_hr_read=>payroll_results(
      iv_pernr   = iv_pernr
      iv_begda   = ls_range-begda
      iv_endda   = ls_range-endda ).
 ENDMETHOD.


  METHOD zif_sadl_read_runtime~execute.
    TYPES: BEGIN OF ts_filter,
             pernr      TYPE pernr-pernr,
             key_date   TYPE d,
             field_name TYPE string,
             pos        TYPE int4,
           END OF ts_filter.

    ASSIGN ir_key->* TO FIELD-SYMBOL(<ls_key>).
    DATA(ls_filter) = CORRESPONDING ts_filter( <ls_key> ).

    " 1 month
    read_py( iv_pernr = ls_filter-pernr
             iv_date  = ls_filter-key_date ).

    get_rt_sum_info( EXPORTING iv_field_name = ls_filter-field_name
                               iv_pos        = ls_filter-pos
                     IMPORTING et_detail     = ct_data_rows ).

    CHECK ls_filter-pos IS NOT INITIAL.
    cv_number_all_hits = lines( ct_data_rows ).
  ENDMETHOD.
ENDCLASS.
