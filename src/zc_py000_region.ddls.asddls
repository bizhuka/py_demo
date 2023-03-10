@AbapCatalog.sqlViewName: 'zvcpy000_region'
@AbapCatalog.compiler.compareFilter: true
@AbapCatalog.preserveKey: true
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Region'


define view ZC_PY000_Region as select from t005u {
    
    key land1,
    
    @ObjectModel.text.element: [ 'bezei' ]
    key bland,
        bezei
} where spras = $session.system_language
