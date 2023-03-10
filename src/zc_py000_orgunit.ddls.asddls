@AbapCatalog.sqlViewName: 'zvcpy000_orgu'
@AbapCatalog.compiler.compareFilter: true
@AbapCatalog.preserveKey: true
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Org Unit'
@Search.searchable

define view ZC_PY000_OrgUnit as select from t527x {
        @Search: { defaultSearchElement: true, fuzzinessThreshold: 0.7 }
        @ObjectModel.text.element: [ 'orgtx' ]
        key orgeh,
        
//        key endda,
//        key begda,
             
            @Search: { defaultSearchElement: true, fuzzinessThreshold: 0.8 }
            orgtx
} where sprsl = $session.system_language and endda = '99991231'
