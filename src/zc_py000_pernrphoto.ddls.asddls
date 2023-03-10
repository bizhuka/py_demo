@AbapCatalog.sqlViewName: 'zvcpy000_avatar'
@AbapCatalog.compiler.compareFilter: true
@AbapCatalog.preserveKey: true
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Avatar by PERNR'

@ZABAP.virtualEntity: 'ZCL_PY000_AVATAR'

define view ZC_PY000_PernrPhoto as select from zdpy000_avatar {
    key pernr,
        img_size
}
