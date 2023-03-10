@AbapCatalog.sqlViewName: 'zvcpy000_workc'
@AbapCatalog.compiler.compareFilter: true
@AbapCatalog.preserveKey: true
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Work Contract'


define view ZC_PY000_WorkContract as select from t542t {    
    @ObjectModel.text.element: [ 'atx' ]
    key ansvh,        
        
        atx
} where spras = $session.system_language and molga = 'KZ'
