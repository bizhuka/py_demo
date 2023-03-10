@AbapCatalog.sqlViewName: 'zvcpy000_pos'
@AbapCatalog.compiler.compareFilter: true
@AbapCatalog.preserveKey: true
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Position'

define view ZC_PY000_Position as select from t528b as _main

association[0..1] to t528t as _Text on _Text.sprsl = $session.system_language
                                   and _Text.otype = 'S' // _main.otype
                                   and _Text.plans = _main.plans
                                   and _Text.endda >= _main.begda
                                   and _Text.begda <= _main.endda
                                   
association[0..1] to zc_py000_longtext as _LongText on _LongText.otype = 'S'
                                                   and _LongText.objid = _main.plans
                                                   and _LongText.subty = 'ZR02'
                                                   and _LongText.begda <= _main.endda
                                                   and _LongText.endda >= _main.begda 
{
    key _main.plans,
    key _main.endda,
        _main.begda,
        
        _Text,
        _LongText        
} where _main.otype = 'S'
