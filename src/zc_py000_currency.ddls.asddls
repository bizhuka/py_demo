@AbapCatalog.sqlViewName: 'zvcpy000_curr'
@AbapCatalog.compiler.compareFilter: true
@AbapCatalog.preserveKey: true
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Currency'
@Search.searchable

define view ZC_PY000_Currency as select from tcurt {
    @Search: { defaultSearchElement: true, fuzzinessThreshold: 0.9 }
    @ObjectModel.text.element: [ 'ltext' ]
    key waers,
    
    @Search: { defaultSearchElement: true, fuzzinessThreshold: 0.7 }
    ltext
} where spras = $session.system_language
