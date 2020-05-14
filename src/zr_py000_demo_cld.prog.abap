*&---------------------------------------------------------------------*
*&---------------------------------------------------------------------*

TYPES:
  " Range of wage types
  tr_lgart TYPE RANGE OF lgart,

  " 1 column
  BEGIN OF ts_column_opt,
    name          TYPE char30,   " Name of column
    text          TYPE text100,  " Label

    rgdir_cond    TYPE text100,  " where for RGDIR
    t_lgart_plus  TYPE tr_lgart, " + sign
    t_lgart_minus TYPE tr_lgart, " - sign
  END OF ts_column_opt,

  " App options
  BEGIN OF ts_option,
    " ALV columns description
    t_column_opt TYPE STANDARD TABLE OF ts_column_opt WITH DEFAULT KEY,

    " Read locked IT ?
    p_locked     TYPE p0001-sprps,

    " for report debuging
    t_debug_usr  TYPE RANGE OF syuname,

    " E-mail
    body    TYPE string,
    subject TYPE text50,
  END OF ts_option,

  "  ALV
  BEGIN OF ts_alv,
    pernr TYPE pernr-pernr,
    ename TYPE p0001-ename,
    werks TYPE p0001-werks,
    btrtl TYPE p0001-btrtl,
    " Other columns is dynamic
  END OF ts_alv,

  " Document structure
  BEGIN OF ts_column,
    name     TYPE char30,
    label    TYPE string,
    col_name TYPE string, " <-- NAME like {R-T-SUM*}
  END OF ts_column,
  tt_column TYPE STANDARD TABLE OF ts_column WITH DEFAULT KEY,

  BEGIN OF ts_merge0,
    a TYPE tt_column, " table of columns In template {C-A}
  END OF ts_merge0,

  BEGIN OF ts_report,
    begda    TYPE begda,
    endda    TYPE endda,
    scr_info TYPE string,
    t        TYPE REF TO data,
  END OF ts_report.

*---------------------------------------------------------------------*
*---------------------------------------------------------------------*
CLASS lcl_email_handler DEFINITION DEFERRED.

CLASS lcl_report DEFINITION FINAL.
  PUBLIC SECTION.
    CONSTANTS:
      BEGIN OF mc_cmd,
        email          TYPE ui_func VALUE 'EMAIL',    " Gos menu pressed
        group_by_werks TYPE syucomm VALUE 'WERKS',    " Change ALV runtime
        download       TYPE syucomm VALUE 'DONWLOAD', " Report button pressed
      END OF mc_cmd.

    DATA:
      " Alv data
      mr_alv           TYPE REF TO data,

      " Options
      ms_option        TYPE ts_option,

      " e-mail button handler
      mo_email_handler TYPE REF TO lcl_email_handler.

    METHODS:
      initialization,

      pbo,

      pai
        IMPORTING
          iv_cmd TYPE syucomm,

      start_of_selection,

      get_peras,

      end_of_selection,

      get_filtered_rt
        IMPORTING
                  is_column_opt    TYPE ts_column_opt
                  it_results       TYPE h99_hr_pay_result_tab
        RETURNING VALUE(rt_result) TYPE hrpay99_rt,

      on_hotspot_click FOR EVENT hotspot_click OF cl_gui_alv_grid
        IMPORTING
            sender
            e_row_id
            e_column_id,

      on_user_command FOR EVENT user_command OF cl_gui_alv_grid
        IMPORTING
            sender
            e_ucomm,

      do_download
        IMPORTING
          iv_send_email TYPE abap_bool OPTIONAL.
ENDCLASS.

CLASS lcl_email_handler DEFINITION FINAL.
  PUBLIC SECTION.
    TYPES:
      " For demo only!
      BEGIN OF ts_context,
        p_uname  TYPE syuname,
        p_chg_id TYPE flag,
      END OF ts_context.

    DATA:
      mo_report TYPE REF TO lcl_report,

      " Gos like menu
      mo_menu   TYPE REF TO zcl_eui_menu.

    METHODS:
      constructor
        IMPORTING
          io_report TYPE REF TO lcl_report,

      start_of_selection,

      on_gos_menu_clicked FOR EVENT function_selected OF cl_gui_toolbar
        IMPORTING
            fcode,

      " on_pbo_event FOR EVENT pbo_event OF zif_eui_manager,

      " OF 1010 screen
      on_pai_event FOR EVENT pai_event OF zif_eui_manager
        IMPORTING
            sender
            iv_command
            cv_close,

      send_to_users
        IMPORTING
          io_xtt TYPE REF TO zcl_xtt,

      get_full_name
        IMPORTING
                  iv_uname            TYPE syuname
        RETURNING VALUE(rv_full_name) TYPE string.
ENDCLASS.
