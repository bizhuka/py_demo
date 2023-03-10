@AbapCatalog.sqlViewName: 'zvcpy000_costt'
@AbapCatalog.compiler.compareFilter: true
@AbapCatalog.preserveKey: true
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Cost Center Type'

define view ZC_PY000_CostCenterType as select from tkt05 {
    @ObjectModel.text.element: [ 'ktext' ]
    key kosar,
    
        ktext
} where spras = $session.system_language
