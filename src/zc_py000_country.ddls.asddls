@AbapCatalog.sqlViewName: 'zvcpy000_country'
@AbapCatalog.compiler.compareFilter: true
@AbapCatalog.preserveKey: true
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Country'
@Search.searchable

define view ZC_PY000_Country as select from t005t {
    @Search: { defaultSearchElement: true, fuzzinessThreshold: 0.9 }
    @ObjectModel.text.element: [ 'CountryText' ]  
    @EndUserText.label: 'Country'
    key land1,
    
        @Search: { defaultSearchElement: true, fuzzinessThreshold: 0.7 }
        landx as CountryText
}where spras = $session.system_language
