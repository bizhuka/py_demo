CLASS zcl_py000_amdp DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC .

  PUBLIC SECTION.
    INTERFACES if_amdp_marker_hdb.
    CLASS-METHODS:
      get_long_texts FOR TABLE FUNCTION zc_py000_longtext.
  PROTECTED SECTION.
  PRIVATE SECTION.
ENDCLASS.



CLASS zcl_py000_amdp IMPLEMENTATION.
  METHOD get_long_texts
          BY DATABASE FUNCTION FOR HDB
          LANGUAGE SQLSCRIPT
          OPTIONS READ-ONLY
          USING hrp1002 hrt1002.

    RETURN
        SELECT  p.mandt,
                p.otype,
                p.objid,
                p.subty,
                p.istat,
                p.begda,
                p.endda,

                string_agg(t.tline, '' order by t.tabseqnr) as long_text
        from hrp1002 as p
            left outer join hrt1002 as t ON t.tabnr = p.tabnr
        where plvar = '01' and langu = session_context('LOCALE_SAP')
        group by p.mandt, p.otype, p.objid, p.subty, p.istat, p.begda, p.endda;
  endmethod.
ENDCLASS.
