*&---------------------------------------------------------------------*
*&---------------------------------------------------------------------*


INITIALIZATION.
  DATA(go_report) = NEW lcl_report( ).
  go_report->initialization( ).

AT SELECTION-SCREEN ON VALUE-REQUEST FOR p_layout.
  zcl_py000=>f4_layouts( CHANGING cv_layout = p_layout ).

AT SELECTION-SCREEN OUTPUT.
  go_report->pbo( ).

AT SELECTION-SCREEN.
  go_report->pai( iv_cmd = sy-ucomm ).

START-OF-SELECTION.
  go_report->start_of_selection( ).

GET peras.
  go_report->get_peras( ).

END-OF-SELECTION.
  go_report->end_of_selection( ).

* LDB PNP
*GET pernr.
*GET payroll.
