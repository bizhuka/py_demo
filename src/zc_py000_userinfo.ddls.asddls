@AbapCatalog.sqlViewName: 'zvcpy000_usrinfo'
@AbapCatalog.compiler.compareFilter: true
@AbapCatalog.preserveKey: true
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'User info'
@Search.searchable

define view ZC_PY000_UserInfo as select from user_addr {
    @Search: { defaultSearchElement: true, fuzzinessThreshold: 0.9 }
    @ObjectModel.text.element: [ 'UserName' ]
    key bname as uname,
    
        @Search: { defaultSearchElement: true, fuzzinessThreshold: 0.7 }
        name_textc as UserName
}
