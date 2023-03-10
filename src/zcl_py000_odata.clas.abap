CLASS zcl_py000_odata DEFINITION
  PUBLIC
  CREATE PUBLIC .

  PUBLIC SECTION.

    INTERFACES:
      zif_sadl_exit,
      zif_sadl_mpc,
      zif_sadl_read_runtime,
      zif_sadl_prepare_read_runtime.

*    METHODS:
*      constructor.

  PROTECTED SECTION.
    TYPES:
      BEGIN OF ts_period,
        key_from TYPE d,
        key_to   TYPE d,
      END OF ts_period,

      BEGIN OF ts_period_field,
        begda    TYPE string,
        endda    TYPE string,
        nullable TYPE abap_bool,
      END OF ts_period_field,
      tt_period_field TYPE STANDARD TABLE OF ts_period_field WITH EMPTY KEY.

    METHODS:
      _get_period_fields RETURNING VALUE(rt_period_field) TYPE tt_period_field,

      _change_org_unit_filter CHANGING  cv_filter    TYPE string,
      _change_period_filter   EXPORTING ev_key_date TYPE d
                              CHANGING  cv_filter   TYPE string.
  PRIVATE SECTION.
    METHODS:
      _get_sub_orgs IMPORTING iv_orgeh TYPE orgeh RETURNING VALUE(rt_result) TYPE tswhactor,

      _set_period_filter   CHANGING ct_sadl_condition TYPE if_sadl_query_types=>tt_complex_condition RETURNING VALUE(rv_key_date) TYPE d,
      _set_org_unit_filter CHANGING ct_sadl_condition TYPE if_sadl_query_types=>tt_complex_condition,

      _get_period_filter IMPORTING is_period TYPE ts_period
                         EXPORTING et_sadl   TYPE if_sadl_query_types=>tt_complex_condition
                                   ev_where  TYPE string.
ENDCLASS.



CLASS ZCL_PY000_ODATA IMPLEMENTATION.


  METHOD zif_sadl_mpc~define.

    TRY.
        DATA(lo_entity) = io_model->get_entity_type( 'ZC_PY000_PernrPhotoType' ).
        lo_entity->set_is_media( abap_true ).
        lo_entity->get_property( 'pernr' )->set_as_content_type( ).
      CATCH /iwbep/cx_mgw_med_exception.
        CLEAR lo_entity.
    ENDTRY.

**********************************************************************
    DATA(lc_fixed_values) = /iwbep/if_mgw_odata_property=>gcs_value_list_type_property-fixed_values.

    DATA(lv_all_fixed_values) =
      |ZC_PY000_EmployeeGroupType-persg;| &&
      |ZC_PY000_EmployeeSubgroupType-persk;| &&
      |ZC_PY000_PersonnelAreaType-persa;| &&
      |ZC_PY000_PersonnelSubAreaType-btrtl;| &&
      |ZC_PY000_CostCenterType-kosar;| &&
      |ZC_PY000_WorkContractType-ansvh;|.

    SPLIT lv_all_fixed_values AT ';' INTO TABLE DATA(lt_all_fixed_values).

    LOOP AT lt_all_fixed_values INTO DATA(lv_pair) WHERE table_line IS NOT INITIAL.
      SPLIT lv_pair AT '-' INTO DATA(lv_entity_type)
                                DATA(lv_field).
      TRY.
          io_model->get_entity_type( CONV #( lv_entity_type ) )->get_property( CONV #( lv_field ) )->set_value_list( lc_fixed_values ).

          " Change also main
          io_model->get_entity_type( iv_entity )->get_property( CONV #( lv_field ) )->set_value_list( lc_fixed_values ).
        CATCH /iwbep/cx_mgw_med_exception.
          CONTINUE.
      ENDTRY.
    ENDLOOP.
  ENDMETHOD.


  METHOD zif_sadl_prepare_read_runtime~change_condition.
    CHECK _set_period_filter( CHANGING ct_sadl_condition = ct_sadl_condition ) IS NOT INITIAL.

    _set_org_unit_filter( CHANGING ct_sadl_condition = ct_sadl_condition ).
  ENDMETHOD.


  METHOD zif_sadl_read_runtime~execute.
    DATA lt_callstack TYPE abap_callstack.
    " Where-Used List
    CALL FUNCTION 'SYSTEM_CALLSTACK'
      EXPORTING
        max_level = 10
      IMPORTING
        callstack = lt_callstack.

    IF line_exists( lt_callstack[ blockname = 'IF_SADL_GW_ODATA_RUNTIME~GET_ENTITY' ] ).
      cv_number_all_hits = 1.
    ENDIF.
  ENDMETHOD.


  METHOD _change_org_unit_filter.
    CONSTANTS cv_needle TYPE string VALUE `and ( ORGEH = '`.

    CHECK cv_filter CS cv_needle.
    DATA(lv_from) = sy-fdpos + strlen( cv_needle ).
    DATA(lv_base_orgeh) = CONV orgeh( cv_filter+lv_from(8) ).

    DATA(lt_org_filter) = VALUE string_table( FOR <ls_line> IN _get_sub_orgs( lv_base_orgeh )
       WHERE ( otype = 'O' ) ( |ORGEH = '{ <ls_line>-objid }'| ) ).
    CHECK lt_org_filter IS NOT INITIAL.

    DATA(lv_filter) = concat_lines_of( table = lt_org_filter sep = | or | ).
    REPLACE FIRST OCCURRENCE OF |'{ lv_base_orgeh }'| IN cv_filter WITH
                                |'{ lv_base_orgeh }' or { lv_filter }|.
  ENDMETHOD.


  METHOD _change_period_filter.
    CONSTANTS cv_needle TYPE string VALUE `and ( KEY_DATE = '`.
    CLEAR ev_key_date.

    CHECK cv_filter CS cv_needle.
    DATA(lv_from) = sy-fdpos + strlen( cv_needle ).
    ev_key_date = CONV d( cv_filter+lv_from(8) ).

    DATA(ls_period) = VALUE ts_period( ).
    ls_period-key_from = ls_period-key_to = ev_key_date.
    _get_period_filter( EXPORTING is_period = ls_period
                        IMPORTING ev_where  = DATA(lv_where) ).

    REPLACE FIRST OCCURRENCE OF |{ cv_needle }{ ev_key_date }' )| IN cv_filter WITH
                                |and { lv_where }|.
  ENDMETHOD.


  METHOD _get_period_fields.
    rt_period_field = VALUE #( ( begda = |BEGDA| endda = |ENDDA| ) ).
  ENDMETHOD.


  METHOD _get_period_filter.
    CLEAR: et_sadl,
           ev_where.

    DATA(lt_range) = VALUE cl_sadl_condition_generator=>tt_grouped_range( ).
    LOOP AT _get_period_fields( ) ASSIGNING FIELD-SYMBOL(<ls_period_field>).
      APPEND VALUE #( column_name = <ls_period_field>-begda field_path = <ls_period_field>-begda t_selopt = VALUE #( ( sign = 'I' option = 'LE' low = is_period-key_to   ) ) ) TO lt_range ASSIGNING FIELD-SYMBOL(<ls_begda>).
      APPEND VALUE #( column_name = <ls_period_field>-endda field_path = <ls_period_field>-endda t_selopt = VALUE #( ( sign = 'I' option = 'GE' low = is_period-key_from ) ) ) TO lt_range ASSIGNING FIELD-SYMBOL(<ls_endda>).

      CHECK <ls_period_field>-nullable = abap_true.
      DATA(c_null) = '77771231'.
      APPEND VALUE #( sign = 'I' option = 'EQ' low = c_null ) TO <ls_begda>-t_selopt.
      APPEND VALUE #( sign = 'I' option = 'EQ' low = c_null ) TO <ls_endda>-t_selopt.
    ENDLOOP.

    cl_sadl_condition_generator=>convert_ranges_to_conditions(
     EXPORTING it_ranges     = lt_range
     IMPORTING et_conditions = et_sadl ).

    CHECK ev_where IS REQUESTED.
    ev_where = zcl_sadl_filter=>get_sadl_where( et_sadl ).
  ENDMETHOD.


  METHOD _get_sub_orgs.
    CALL FUNCTION 'RH_STRUC_GET'
      EXPORTING
        act_otype  = 'O'
        act_objid  = iv_orgeh
        act_wegid  = 'B002'
        act_plvar  = '01'
      TABLES
        result_tab = rt_result
      EXCEPTIONS
        OTHERS     = 0.
  ENDMETHOD.


  METHOD _set_org_unit_filter.
    READ TABLE ct_sadl_condition TRANSPORTING NO FIELDS
     WITH KEY type = 'equals' attribute = 'ORGEH'.
    CHECK sy-subrc = 0.
    DATA(lv_pos_insert) = sy-tabix.

    DATA(lt_result) = _get_sub_orgs( CONV #( ct_sadl_condition[ lv_pos_insert - 1 ]-value ) ).
    CHECK lt_result[] IS NOT INITIAL.

    ADD 1 TO lv_pos_insert.
    LOOP AT lt_result ASSIGNING FIELD-SYMBOL(<ls_result>) WHERE otype = 'O'.
      DATA(lt_new_filter) = VALUE if_sadl_query_types=>tt_complex_condition(
        ( type = 'simpleValue' value     = <ls_result>-objid )
        ( type = 'equals'      attribute = 'ORGEH' )
        ( type = 'or' )
      ).

      INSERT LINES OF lt_new_filter INTO ct_sadl_condition INDEX lv_pos_insert.
      lv_pos_insert = lv_pos_insert + lines( lt_new_filter ).
    ENDLOOP.
  ENDMETHOD.


  METHOD _set_period_filter.
    " between ?
    READ TABLE ct_sadl_condition TRANSPORTING NO FIELDS
     WITH KEY type = 'equals' attribute = 'KEY_DATE'.
    CHECK sy-subrc = 0.

    DATA(lv_tabix) = sy-tabix.
    rv_key_date = ct_sadl_condition[ lv_tabix - 1 ]-value.

    DATA(ls_period) = VALUE ts_period( ).
    ls_period-key_from = ls_period-key_to = rv_key_date.
    DELETE ct_sadl_condition FROM lv_tabix - 1 TO lv_tabix.

    _get_period_filter( EXPORTING is_period = ls_period
                        IMPORTING et_sadl   = DATA(lt_condition) ).
    INSERT LINES OF lt_condition INTO ct_sadl_condition INDEX 1.
  ENDMETHOD.
ENDCLASS.
