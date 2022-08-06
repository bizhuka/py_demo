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
protected section.
private section.

  class-data MT_MONTH_NAME type ref to FTPS_WEB_MONTH_T .

  class-methods _INIT_MONTH_TEXTS .
ENDCLASS.



CLASS ZCL_HR_MONTH IMPLEMENTATION.


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
