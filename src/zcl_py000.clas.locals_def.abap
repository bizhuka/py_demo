*"* use this source file for any type of declarations (class
*"* definitions, interfaces or type declarations) you need for
*"* components in the private section

CLASS lcl_regular_pay DEFINITION INHERITING FROM cl_hrpay99_prr_4_pnp_payper FINAL.
  PUBLIC SECTION.
    TYPES:
      BEGIN OF ts_pernr_rgdir,
        pernr  TYPE pernr-pernr,
        loaded TYPE abap_bool,
        molga  TYPE molga,
        rgdir  TYPE hrpy_tt_rgdir,
      END OF ts_pernr_rgdir,
      tt_pernr_rgdir TYPE SORTED TABLE OF ts_pernr_rgdir WITH UNIQUE KEY pernr,

      BEGIN OF ts_payroll,
        molga      TYPE molga,
        pay_period TYPE faper,
        payroll    TYPE REF TO cl_hrpay99_prr_4_pnp_reps,
      END OF ts_payroll.

    CLASS-DATA:
      mv_py_mode     TYPE string,
      mt_pernr_rgdir TYPE tt_pernr_rgdir,

      " All payrolls
      mt_payroll     TYPE SORTED TABLE OF ts_payroll WITH UNIQUE KEY molga pay_period.

    CLASS-METHODS:
      init
        IMPORTING
          iv_py_mode LIKE mv_py_mode
          iv_begda   TYPE begda
          iv_endda   TYPE endda
          it_pernr   TYPE zcl_py000=>tt_pernr,

      get_payroll
        IMPORTING
                  iv_pernr                TYPE pernr-pernr
                  iv_pay_period           TYPE faper
                  iv_permo                TYPE permo DEFAULT '01'
                  iv_ipview               TYPE h99_ipview
                  iv_add_retroes_to_rgdir TYPE h99_add_retroes
                  iv_arch_too             TYPE arch_too
        RETURNING VALUE(ro_payroll)       TYPE REF TO cl_hrpay99_prr_4_pnp_reps.

  PROTECTED SECTION.
    METHODS:
      read_rgdir_from
        IMPORTING
          iv_tabix TYPE sytabix,

      read_whole_rgdir REDEFINITION.
ENDCLASS.
