@AbapCatalog.sqlViewName: 'zvcpy000_costc'
@AbapCatalog.compiler.compareFilter: true
@AbapCatalog.preserveKey: true
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Cost Center'
@Search.searchable

define view ZC_PY000_CostCenter as select from csks as _main
association [0..1] to cskt as _text on _text.kokrs = _main.kokrs
                          and _text.kostl = _main.kostl
                          and _text.datbi = _main.datbi

association [0..1] to ZC_PY000_CostCenterType    as _CostCenterType    on _CostCenterType.kosar = _main.kosar

 {
    key _main.kokrs,
    
    @Search: { defaultSearchElement: true, fuzzinessThreshold: 0.7 }
    @ObjectModel.text.element: [ 'ltext' ]
    key _main.kostl,
         
        @Consumption.valueHelp: '_CostCenterType'
        _main.kosar,
        _CostCenterType,        
    
        @Search: { defaultSearchElement: true, fuzzinessThreshold: 0.8 }
        _text.ltext
} where _text.spras = $session.system_language and _main.datbi = '99991231'
