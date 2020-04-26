*&---------------------------------------------------------------------*
* The selection screen can be customized by assigning a PNP(CE) payroll*
* reportclass to this report (the default is PY_DEF): Go to ->         *
* report properties -> Button HR reportclass -> check the box "Payroll *
*-reportclass -> Press create to enter the customizing view.           *
*&---------------------------------------------------------------------*

TABLES pernr.

NODES peras.

INFOTYPES 0001.

SELECTION-SCREEN BEGIN OF BLOCK bl_opt WITH FRAME TITLE TEXT-opt.
PARAMETERS:
  p_layout TYPE disvariant-variant,
  p_std    AS CHECKBOX.
SELECTION-SCREEN END OF BLOCK bl_opt.

" e-mail button screen
SELECTION-SCREEN BEGIN OF SCREEN 1010 AS SUBSCREEN.
PARAMETERS:
  " check it in PAI
  p_uname  TYPE suid_st_bname-bname DEFAULT sy-uname OBLIGATORY,

  " Can change P_UNAME ?
  p_chg_id AS CHECKBOX DEFAULT ' ' MODIF ID gry.
SELECTION-SCREEN END OF SCREEN 1010.

** " PNP ldb For the selection-screen
** " Use '900' as selection screen (report attributes)
*TABLES pyorgscreen.
*TABLES pytimescreen.
*NODES payroll TYPE pay99_result. " XX = country code
