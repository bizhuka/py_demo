class ZCL_HR_MONTH definition
  public
  final
  create private .

public section.

  types:
    BEGIN OF ts_range,
        begda TYPE d,
        endda TYPE d,
      END OF ts_range .

  constants:
    BEGIN OF mc_lang,
        kaz TYPE sylangu VALUE '뱋',
        rus TYPE sylangu VALUE 'R',
        eng TYPE sylangu VALUE 'E',
      END OF mc_lang .
  constants:
    BEGIN OF mc_period,
        day     TYPE char10 VALUE 'DAY',
        week    TYPE char10 VALUE 'WEEK',
        month   TYPE char10 VALUE 'MONTH',
        quarter TYPE char10 VALUE 'QUARTER',
        year    TYPE char10 VALUE 'YEAR',
      END OF mc_period .

  class-methods GET_RANGE
    importing
      !IV_BEGDA type BEGDA
    returning
      value(RS_RANGE) type TS_RANGE .
  class-methods GET_TEXT
    importing
      !IV_LANGU type SYLANGU default SY-LANGU
      !IV_MONTH type T247-MNR
    returning
      value(RV_TEXT) type STRING .
  class-methods GET_PERIOD_START_DATE
    importing
      !IV_PERIOD type CHAR10
      !IV_OFFSET type I default 0
      !IV_DATUM type D default SY-DATUM
    returning
      value(RV_DATE) type D .
  PROTECTED SECTION.
  PRIVATE SECTION.

    CLASS-DATA mt_month_name TYPE REF TO ftps_web_month_t .

    CLASS-METHODS _init_month_texts .
ENDCLASS.



CLASS ZCL_HR_MONTH IMPLEMENTATION.


  METHOD get_period_start_date.
    CASE iv_period.
      WHEN mc_period-day.
        rv_date = iv_datum + iv_offset.

      WHEN mc_period-week.
        DATA(lv_week) = CONV scal-week( '000000' ).
        CALL FUNCTION 'DATE_GET_WEEK'
          EXPORTING
            date   = CONV d( iv_datum + 7 * iv_offset )
          IMPORTING
            week   = lv_week
          EXCEPTIONS
            OTHERS = 2.
        IF sy-subrc <> 0.
          zcx_eui_no_check=>raise_sys_error( ).
        ENDIF.

        CALL FUNCTION 'WEEK_GET_FIRST_DAY'
          EXPORTING
            week   = lv_week
          IMPORTING
            date   = rv_date
          EXCEPTIONS
            OTHERS = 2.
        IF sy-subrc <> 0.
          zcx_eui_no_check=>raise_sys_error( ).
        ENDIF.

      WHEN mc_period-month.
        rv_date = cl_reca_date=>add_months_to_date( id_date   = iv_datum
                                                    id_months = iv_offset ).
        rv_date = |{ rv_date(6) }01|.

      WHEN mc_period-quarter.
        rv_date = cl_reca_date=>add_months_to_date( id_date   = iv_datum
                                                    id_months = iv_offset * 3 ).

        DATA(lv_month) = SWITCH #( rv_date+4(2) WHEN '01' OR '02' OR '03' THEN '01'
                                                WHEN '04' OR '05' OR '06' THEN '04'
                                                WHEN '07' OR '08' OR '09' THEN '07'
                                                WHEN '10' OR '11' OR '12' THEN '10' ).
        rv_date = rv_date(4) && lv_month && '01'.

      WHEN mc_period-year.
        rv_date = CONV char4( iv_datum(4) + iv_offset ) && '0101'.

      WHEN OTHERS.
        zcx_eui_exception=>raise_dump( iv_message = |Wrong period { iv_period }| ).
    ENDCASE.
  ENDMETHOD.


  METHOD get_range.
    " Set start date
    rs_range-begda = iv_begda. "+0(6).

    " End of month
    rs_range-endda = rs_range-begda + 32.
    rs_range-endda = rs_range-endda+0(6) && '01'.
    rs_range-endda = rs_range-endda - 1.
  ENDMETHOD.


  METHOD get_text.
    " 1 time only
    _init_month_texts( ).

    READ TABLE mt_month_name->*[] ASSIGNING FIELD-SYMBOL(<ls_month_name>) BINARY SEARCH
     WITH KEY spras = iv_langu
              mnr   = iv_month.
    CHECK sy-subrc = 0.

    rv_text = <ls_month_name>-ltx.
  ENDMETHOD.


  METHOD _init_month_texts.
    CHECK mt_month_name IS INITIAL.
    mt_month_name = NEW #( ).

    " For months
    DATA(lt_langu) = VALUE rstt_t_langu( ( mc_lang-kaz ) ( mc_lang-rus ) ( mc_lang-eng ) ).
    LOOP AT lt_langu ASSIGNING FIELD-SYMBOL(<ls_langu>).
      DATA(lt_month_name) = VALUE ftps_web_month_t( ).
      CALL FUNCTION 'MONTH_NAMES_GET'
        EXPORTING
          language              = <ls_langu>
        TABLES
          month_names           = lt_month_name[]
        EXCEPTIONS
          month_names_not_found = 1
          OTHERS                = 2.
      CHECK sy-subrc = 0.

      APPEND LINES OF lt_month_name TO mt_month_name->*[].
    ENDLOOP.

    " For speed
    SORT mt_month_name->*[] BY spras mnr.
  ENDMETHOD.
ENDCLASS.
