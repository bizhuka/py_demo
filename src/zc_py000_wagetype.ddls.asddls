@AbapCatalog.sqlViewName: 'zvcpy000_wt'
@AbapCatalog.compiler.compareFilter: true
@AbapCatalog.preserveKey: true
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Wage type'
@Search.searchable: true

define view ZC_PY000_WageType as select from t512w as _main
inner join t512t as _text on _text.sprsl = $session.system_language
                         and _text.molga = _main.molga
                         and _text.lgart = _main.lgart
{
    @Search: { defaultSearchElement: true, fuzzinessThreshold: 0.7 }
    @ObjectModel.text.element: [ 'lgtxt' ]
    key _main.lgart,
        
        @Search: { defaultSearchElement: true, fuzzinessThreshold: 0.8 }
        _text.lgtxt
} where _main.molga = 'KZ' and _main.endda = '99991231'
