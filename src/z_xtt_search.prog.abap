*&---------------------------------------------------------------------*
*&---------------------------------------------------------------------*
REPORT z_xtt_search.

TABLES:
  wwwdata.

SELECT-OPTIONS:
 s_objid FOR wwwdata-objid OBLIGATORY.
PARAMETERS:
 p_text TYPE text255 DEFAULT ';direction=column' OBLIGATORY.

**********************************************************************
**********************************************************************
INITIALIZATION.
  PERFORM initialization.

START-OF-SELECTION.
  PERFORM go.

FORM initialization.
  s_objid[] = VALUE #( ( sign = 'I' option = 'CP' low = 'Z*' ) ).
ENDFORM.

FORM go.
  SELECT DISTINCT objid INTO TABLE @DATA(lt_objid)  "#EC "#EC CI_NOFIRST
  FROM wwwdata
  WHERE objid IN @s_objid[].

  DATA(lt_path) = VALUE stringtab( ( |word/document.xml| )
                                   ( |xl/sharedStrings.xml| )
                                   ( |xl/worksheets/sheet1.xml| )
                                   ( |xl/worksheets/sheet2.xml| )
                                   ( |xl/worksheets/sheet3.xml| )
                                   ( |xl/worksheets/sheet4.xml| )
                                   ( |xl/worksheets/sheet5.xml| )
                                   ).

  LOOP AT lt_objid ASSIGNING FIELD-SYMBOL(<ls_objid>).
    TRY.
        DATA(lo_template) = CAST zif_xtt_file( NEW zcl_xtt_file_smw0( <ls_objid>-objid ) ).
        lo_template->get_content( IMPORTING ev_as_xstring = DATA(lv_zip) ).
      CATCH zcx_eui_no_check.
        CONTINUE.
    ENDTRY.

    DATA(lo_zip) = NEW cl_abap_zip( ).
    lo_zip->load( lv_zip ).

    DATA(lv_max_empty) = 2.
    DATA(lv_write_objid) = abap_true.
    LOOP AT lt_path INTO DATA(lv_path).
      zcl_eui_conv=>xml_from_zip( EXPORTING io_zip  = lo_zip
                                            iv_name = lv_path
                                  IMPORTING ev_sdoc = DATA(lv_xml) ).
      IF lv_xml IS INITIAL.
        SUBTRACT 1 FROM lv_max_empty.
        IF lv_max_empty IS INITIAL.
          EXIT.
        ENDIF.
        CONTINUE.
      ENDIF.

      DO 1 TIMES.
        CHECK lv_xml CS p_text.
        IF lv_write_objid = abap_true.
          lv_write_objid = abap_false.
          WRITE: / <ls_objid>-objid COLOR COL_POSITIVE.
        ENDIF.
        WRITE: / lv_path, / lv_xml+sy-fdpos(*).
      ENDDO.

      CLEAR lv_xml.
    ENDLOOP.
  ENDLOOP.
ENDFORM.
