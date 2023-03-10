@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Long Text'

define table function ZC_PY000_LongText
returns {
        key mandt:     mandt;
        key otype:     otype;
        key objid:     hrobjid;
        key subty:     subtyp;
        key istat:     istat_d;
        key begda:     begdatum;
        key endda:     enddatum;
            long_text: abap.char( 1000 );
                            
} implemented by method zcl_py000_amdp=>get_long_texts;
