class ZCL_PY000 definition
  public
  final
  create private .

public section.
  type-pools ABAP .

  types TS_PAYROLL_RESULTS type ZCL_HR_READ=>TS_PAYROLL_RESULTS .
  types TT_PAYROLL_RESULTS type ZCL_HR_READ=>TT_PAYROLL_RESULTS .
  types TS_DATE_PERIOD type ZCL_HR_MONTH=>TS_RANGE .
  types TT_PERNR type ZCL_HR_READ=>TT_PERNR .

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
ENDCLASS.
