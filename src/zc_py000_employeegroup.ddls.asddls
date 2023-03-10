@AbapCatalog.sqlViewName: 'zvcpy000_persg'
@AbapCatalog.compiler.compareFilter: true
@AbapCatalog.preserveKey: true
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Employee Group'
@ObjectModel.resultSet.sizeCategory: #XS

define view ZC_PY000_EmployeeGroup as select from t501t {
    
    @ObjectModel.text.element: [ 'ptext' ]
    key persg,
        
        @Semantics.text: true
        ptext
}where sprsl = $session.system_language
