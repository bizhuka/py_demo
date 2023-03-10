@AbapCatalog.sqlViewName: 'zvcpy000_stvarv'
@AbapCatalog.compiler.compareFilter: true
@AbapCatalog.preserveKey: true
@AccessControl.authorizationCheck: #CHECK
@EndUserText.label: 'Old fashioned option based on STVARV'

// Small options without tr. ZAQO
define view ZC_PY000_STVARV as select from tvarvc {
    key name,
    key type,
    key numb,
        sign,
        opti,
        low,
        high,
        
        cast (substring( cast( tstmp_current_utctimestamp() as abap.char(17) ), 1, 8 ) as abap.dats) as datum
}
