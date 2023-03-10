@AbapCatalog.sqlViewName: 'zvcpy000_persa'
@AbapCatalog.compiler.compareFilter: true
@AbapCatalog.preserveKey: true
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Personnel Area'

define view ZC_PY000_PersonnelArea as select from t500p {
    @ObjectModel.text.element: [ 'name1' ]    
    key persa,
    
    key name1       
} where molga = 'KZ'
