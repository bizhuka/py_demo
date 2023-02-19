*"* use this source file for any type of declarations (class
*"* definitions, interfaces or type declarations) you need for
*"* components in the private section

CLASS lcl_regular_pay DEFINITION INHERITING FROM cl_hrpay99_prr_4_pnp_payper FINAL.
  PUBLIC SECTION.
    TYPES:
      BEGIN OF ts_pernr_rgdir,
        pernr  TYPE pernr-pernr,
        molga  TYPE molga,
        loaded TYPE abap_bool,
        rgdir  TYPE hrpy_tt_rgdir,
      END OF ts_pernr_rgdir,
      tt_pernr_rgdir TYPE SORTED TABLE OF ts_pernr_rgdir WITH UNIQUE KEY pernr,

      BEGIN OF ts_payroll,
        molga          TYPE molga,
        pay_period     TYPE faper,

        " Base class
        payroll        TYPE REF TO cl_hrpay99_prr_4_pnp_reps,
        " regular & off-cycle run
        payroll_payper TYPE REF TO cl_hrpay99_prr_4_pnp_payper,
        " everything within a single day
        payroll_sngday TYPE REF TO cl_hrpay99_prr_4_pnp_sngday,
        " everything within a timespan
        payroll_tispan TYPE REF TO cl_hrpay99_prr_4_pnp_tispan,
      END OF ts_payroll.

    CLASS-DATA:
      mt_pernr_rgdir TYPE tt_pernr_rgdir,

      " All payrolls
      mt_payroll     TYPE SORTED TABLE OF ts_payroll WITH UNIQUE KEY molga pay_period.

    CLASS-METHODS:
*      init
*        IMPORTING
*          iv_begda TYPE begda
*          iv_endda TYPE endda
*          iv_molga TYPE molga,

      get_payroll
        IMPORTING
                  iv_pernr                TYPE pernr-pernr

                  iv_begda                TYPE begda
                  iv_endda                TYPE endda
                  iv_molga                TYPE molga
                  iv_std_class            TYPE abap_bool

                  iv_pay_period           TYPE faper
                  iv_permo                TYPE permo
                  iv_ipview               TYPE h99_ipview
                  iv_add_retroes_to_rgdir TYPE h99_add_retroes
                  iv_arch_too             TYPE arch_too
        RETURNING VALUE(rs_payroll)       TYPE ts_payroll.

  PROTECTED SECTION.
    METHODS:
      read_rgdir_from
        IMPORTING
          iv_tabix TYPE sytabix,

      read_whole_rgdir REDEFINITION.
ENDCLASS.
