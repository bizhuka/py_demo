@AbapCatalog.sqlViewName: 'zvcpy000_persk'
@AbapCatalog.compiler.compareFilter: true
@AbapCatalog.preserveKey: true
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Employee Subgroup'

define view ZC_PY000_EmployeeSubgroup as select from t503t {    
    @ObjectModel.text.element: [ 'ptext' ]
    key persk,        
        
        ptext
}where sprsl = $session.system_language and persk like '1%'
