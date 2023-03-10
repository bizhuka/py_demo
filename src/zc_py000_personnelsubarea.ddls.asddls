@AbapCatalog.sqlViewName: 'zvcpy000_persb'
@AbapCatalog.compiler.compareFilter: true
@AbapCatalog.preserveKey: true
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Personnel SubArea'

define view ZC_PY000_PersonnelSubArea as select from t001p {   
    key werks as persa,
    
    @ObjectModel.text.element: [ 'btext' ]    
    key btrtl,
        
        btext
} where molga = 'KZ'
