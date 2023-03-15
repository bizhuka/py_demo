@AbapCatalog.sqlViewName: 'zvcpy000_rep_rt'
@AbapCatalog.compiler.compareFilter: true
@AbapCatalog.preserveKey: true
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Drilldown info of RT (filled at runtime)'


@ZABAP.virtualEntity: 'ZCL_PY000_REPORT_RT'
define view ZC_PY000_REPORT_RT as select from zdpy000_rt_dd as _dd

association [0..1] to ZC_PY000_WageType as _WageType on _WageType.lgart = _dd.lgart
{
    key pernr,    
    
    // report to key date (1 month)
    key cast('99991231' as abap.dats ) as key_date,
    
    // Connection field
    key 'SUM_*' as field_name, 
    
    key cast(0 as abap.int4 )  as pos,
    
    @UI.lineItem: [{ position: 10 }]
    @UI.fieldGroup: [{ position: 10, qualifier: 'GrpPY' }]    
    faper,
    
    @UI.lineItem: [{ position: 20 }]
    @UI.fieldGroup: [{ position: 20, qualifier: 'GrpPY' }]
    payty,
    
    @UI.lineItem: [{ position: 30 }]
    @UI.fieldGroup: [{ position: 30, qualifier: 'GrpOther' }]
    seqnr,
    
    @UI.lineItem: [{ position: 40 }]
    @UI.fieldGroup: [{ position: 40, qualifier: 'GrpOther' }]
    abkrs,
    
    @UI.lineItem: [{ position: 50 }]
    @UI.fieldGroup: [{ position: 50, qualifier: 'GrpOther' }]
    ocrsn,
    
    @UI.lineItem: [{ position: 60 }]
    @UI.fieldGroup: [{ position: 60, qualifier: 'GrpOther' }]
    fpper,
    
    @UI.lineItem: [{ position: 70 }]
    @UI.fieldGroup: [{ position: 70, qualifier: 'GrpOther' }]
    inper,
    
    @UI.lineItem: [{ position: 80 }]
    @UI.fieldGroup: [{ position: 80, qualifier: 'GrpOther' }]
    srtza,
    
    @UI.lineItem: [{ position: 90, importance: #HIGH }]
    @UI.fieldGroup: [{ position: 130, qualifier: 'GrpMain' }]
    @Consumption.valueHelp: '_WageType'
    lgart,
    _WageType,
    
    @UI.lineItem: [{ position: 100 }]
    @UI.fieldGroup: [{ position: 100, qualifier: 'GrpOther' }]
    betpe,
    
    @UI.lineItem: [{ position: 110 }]
    @UI.fieldGroup: [{ position: 110, qualifier: 'GrpOther' }]
    anzhl,
    
    @UI.lineItem: [{ position: 120, importance: #HIGH }]
    @UI.fieldGroup: [{ position: 120, qualifier: 'GrpMain' }]
    betrg
}
