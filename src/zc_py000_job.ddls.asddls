@AbapCatalog.sqlViewName: 'zvcpy000_job'
@AbapCatalog.compiler.compareFilter: true
@AbapCatalog.preserveKey: true
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Job'

define view ZC_PY000_Job as select from t513 as _main

association[0..1] to t513s as _Text on _Text.sprsl = $session.system_language
                                   and _Text.stell = _main.stell
                                   and _Text.endda >= _main.begda
                                   and _Text.begda <= _main.endda
// TODO
//association[0..1] to ZC_PY000_LongText as _LongText on _LongText.otype = 'C'
//                                                   and _LongText.objid = _main.plans
//                                                   and _LongText.subty = 'ZR02' ?
//                                                   and _LongText.begda <= _main.endda
//                                                   and _LongText.endda >= _main.begda 
{
    key _main.stell,
    key _main.endda,
        _main.begda,
        
        _Text
        //_LongText
}
