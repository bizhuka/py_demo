@AbapCatalog.sqlViewName: 'zvcpy000_country'
@AbapCatalog.compiler.compareFilter: true
@AbapCatalog.preserveKey: true
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Country'


define view ZC_PY000_Country as select from t005t {
    @ObjectModel.text.element: [ 'landx' ]  
    @EndUserText.label: 'Country'
    key land1,
    
        landx
}where spras = $session.system_language
