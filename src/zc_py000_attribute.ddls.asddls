@AbapCatalog.sqlViewName: 'zvcpy000_attr'
@AbapCatalog.compiler.compareFilter: true
@AbapCatalog.preserveKey: true
@AccessControl.authorizationCheck: #CHECK
@EndUserText.label: 'Attribute'


define view ZC_PY000_Attribute as select from hrp1222 as _main
    inner join hrt1222 as t on t.tabnr = _main.tabnr
{
//    key plvar,
    key otype,
    key objid,
    key subty,
    key istat,
    key begda,
    key endda,
    key varyf,
    key seqnr,
    
    _main.infty,
    _main.otjid,
    _main.tabnr,
    
    t.attrib,
    t.low
} where plvar = '01'
