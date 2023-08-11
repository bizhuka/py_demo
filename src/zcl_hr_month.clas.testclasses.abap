*"* use this source file for your ABAP unit test classes

CLASS lcl_test DEFINITION FINAL FOR TESTING RISK LEVEL HARMLESS
                                            DURATION   MEDIUM.
  PUBLIC SECTION.

  PRIVATE SECTION.
    METHODS:
      day_0 FOR TESTING,
      day_1 FOR TESTING,

      week_0 FOR TESTING,
      week_1 FOR TESTING,
      week_2 FOR TESTING,

      month_0 FOR TESTING,
      month_1 FOR TESTING,
      month_2 FOR TESTING,

      quarter_0 FOR TESTING,
      quarter_1 FOR TESTING,
      quarter_2 FOR TESTING,

      year_0 FOR TESTING,
      year_1 FOR TESTING,
      year_2 FOR TESTING.
ENDCLASS.

CLASS lcl_test IMPLEMENTATION.
  METHOD day_0.
    cl_abap_unit_assert=>assert_equals( exp = sy-datum
                                        act = zcl_hr_month=>get_period_start_date( iv_period = zcl_hr_month=>mc_period-day ) ).

  ENDMETHOD.

  METHOD day_1.
    cl_abap_unit_assert=>assert_equals( exp = CONV d( sy-datum - 1 )
                                        act = zcl_hr_month=>get_period_start_date( iv_period = zcl_hr_month=>mc_period-day
                                                                                   iv_offset = -1 ) ).
  ENDMETHOD.

  METHOD week_0.
    cl_abap_unit_assert=>assert_equals( exp = '20230605'
                                        act = zcl_hr_month=>get_period_start_date( iv_datum  = '20230608'
                                                                                   iv_period = zcl_hr_month=>mc_period-week ) ).
  ENDMETHOD.

  METHOD week_1.
    cl_abap_unit_assert=>assert_equals( exp = '20230529'
                                        act = zcl_hr_month=>get_period_start_date( iv_datum  = '20230608'
                                                                                   iv_offset = -1
                                                                                   iv_period = zcl_hr_month=>mc_period-week ) ).
  ENDMETHOD.

  METHOD week_2.
    cl_abap_unit_assert=>assert_equals( exp = '20230612'
                                        act = zcl_hr_month=>get_period_start_date( iv_datum  = '20230608'
                                                                                   iv_offset = 1
                                                                                   iv_period = zcl_hr_month=>mc_period-week ) ).
  ENDMETHOD.

  METHOD month_0.
    cl_abap_unit_assert=>assert_equals( exp = '20230601'
                                        act = zcl_hr_month=>get_period_start_date( iv_datum  = '20230608'
                                                                                   iv_period = zcl_hr_month=>mc_period-month ) ).
  ENDMETHOD.

  METHOD month_1.
    cl_abap_unit_assert=>assert_equals( exp = '20230501'
                                        act = zcl_hr_month=>get_period_start_date( iv_datum  = '20230608'
                                                                                   iv_offset = -1
                                                                                   iv_period = zcl_hr_month=>mc_period-month ) ).
  ENDMETHOD.

  METHOD month_2.
    cl_abap_unit_assert=>assert_equals( exp = '20230701'
                                        act = zcl_hr_month=>get_period_start_date( iv_datum  = '20230608'
                                                                                   iv_offset = 1
                                                                                   iv_period = zcl_hr_month=>mc_period-month ) ).
  ENDMETHOD.

  METHOD quarter_0.
    cl_abap_unit_assert=>assert_equals( exp = '20230401'
                                        act = zcl_hr_month=>get_period_start_date( iv_datum  = '20230608'
                                                                                   iv_period = zcl_hr_month=>mc_period-quarter ) ).
  ENDMETHOD.

  METHOD quarter_1.
    cl_abap_unit_assert=>assert_equals( exp = '20230101'
                                        act = zcl_hr_month=>get_period_start_date( iv_datum  = '20230608'
                                                                                   iv_offset = -1
                                                                                   iv_period = zcl_hr_month=>mc_period-quarter ) ).
  ENDMETHOD.

  METHOD quarter_2.
    cl_abap_unit_assert=>assert_equals( exp = '20230701'
                                        act = zcl_hr_month=>get_period_start_date( iv_datum  = '20230608'
                                                                                   iv_offset = 1
                                                                                   iv_period = zcl_hr_month=>mc_period-quarter ) ).
  ENDMETHOD.

  METHOD year_0.
    cl_abap_unit_assert=>assert_equals( exp = '20230101'
                                        act = zcl_hr_month=>get_period_start_date( iv_datum  = '20230608'
                                                                                   iv_period = zcl_hr_month=>mc_period-year ) ).
  ENDMETHOD.

  METHOD year_1.
    cl_abap_unit_assert=>assert_equals( exp = '20220101'
                                        act = zcl_hr_month=>get_period_start_date( iv_datum  = '20230608'
                                                                                   iv_offset = -1
                                                                                   iv_period = zcl_hr_month=>mc_period-year ) ).
  ENDMETHOD.

  METHOD year_2.
    cl_abap_unit_assert=>assert_equals( exp = '20240101'
                                        act = zcl_hr_month=>get_period_start_date( iv_datum  = '20230608'
                                                                                   iv_offset = 1
                                                                                   iv_period = zcl_hr_month=>mc_period-year ) ).
  ENDMETHOD.


ENDCLASS.
