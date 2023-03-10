@AbapCatalog.sqlViewName: 'zvcpy000_0001'
@AbapCatalog.compiler.compareFilter: true
@AbapCatalog.preserveKey: true
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Org. Assignment'
@Search.searchable

@OData.publish: true

@ZABAP.virtualEntity: 'ZCL_PY000_ODATA'
define view ZC_PY000_OrgAssignment as select from pa0001 as _org_assign

association [0..1] to ZC_PY000_EmployeeGroup    as _EmployeeGroup    on _EmployeeGroup.persg = _org_assign.persg
association [0..1] to ZC_PY000_EmployeeSubgroup as _EmployeeSubgroup on _EmployeeSubgroup.persk = _org_assign.persk
association [0..1] to ZC_PY000_PersonnelArea    as _PersonnelArea    on _PersonnelArea.persa = _org_assign.werks
association [0..1] to ZC_PY000_PersonnelSubArea as _PersonnelSubArea on _PersonnelSubArea.persa = _org_assign.werks
                                                                    and _PersonnelSubArea.btrtl = _org_assign.btrtl  
association [0..1] to ZC_PY000_WorkContract     as _WorkContract     on _WorkContract.ansvh = _org_assign.ansvh
association [0..1] to ZC_PY000_CostCenter       as _CostCenter       on _CostCenter.kokrs = _org_assign.kokrs
                                                                    and _CostCenter.kostl = _org_assign.kostl 
association [0..1] to ZC_PY000_OrgUnit          as _OrgUnit          on _OrgUnit.orgeh = _org_assign.orgeh
association [0..1] to ZC_PY000_Position         as _Position         on _Position.plans = _org_assign.plans
association [0..1] to ZC_PY000_Job              as _Job              on _Job.stell = _org_assign.stell

association [0..1] to ZC_PY000_PernrPhoto       as _Photo            on _Photo.pernr = _org_assign.pernr


{
    @Search: { defaultSearchElement: true, fuzzinessThreshold: 0.7 }
    key pernr,
    key endda,
    key begda,
        
        @Search: { defaultSearchElement: true, fuzzinessThreshold: 0.8 }
        ename,
        
        // Current date
        @Consumption.filter: { selectionType: #INTERVAL, multipleSelections: false } 
        cast (substring( cast( tstmp_current_utctimestamp() as abap.char(17) ), 1, 8 ) as abap.dats) as datum,
        
        @UI.selectionField: [{ position: 10 }]
        @UI.fieldGroup: [{ qualifier: 'Org', position: 10 }]
        @Consumption.valueHelp: '_EmployeeGroup'
        persg,
        
        @UI.selectionField: [{ position: 20 }]    
        @UI.fieldGroup: [{ qualifier: 'Org', position: 20 }]
        @Consumption.valueHelp: '_EmployeeSubgroup'
        persk,
        
        @UI.selectionField: [{ position: 30 }]
        @UI.fieldGroup: [{ qualifier: 'Org', position: 30 }]
        @Consumption.valueHelp: '_PersonnelArea'
        werks as persa,
        
        @UI.selectionField: [{ position: 40 }]
        @UI.fieldGroup: [{ qualifier: 'Org', position: 40 }]
        @Consumption.valueHelp: '_PersonnelSubArea'
        btrtl,
        
        @UI.selectionField: [{ position: 45 }]
        @UI.fieldGroup: [{ qualifier: 'Org', position: 45 }]
        @Consumption.valueHelp: '_WorkContract'
        ansvh,
        
        kokrs,
        @UI.selectionField: [{ position: 50 }]
        @UI.fieldGroup: [{ qualifier: 'Org', position: 50 }]
        @Consumption.valueHelp: '_CostCenter'
        kostl,
        
        @UI.selectionField: [{ position: 60 }]
        @UI.fieldGroup: [{ qualifier: 'Org', position: 60 }]
        @Consumption.valueHelp: '_OrgUnit'
        orgeh,
        
        @UI.fieldGroup: [{ qualifier: 'Org', position: 70 }]
        @Consumption.valueHelp: '_Position'
        plans,
        
        @UI.fieldGroup: [{ qualifier: 'Org', position: 80 }]
        @Consumption.valueHelp: '_Job'
        stell,
        
        bukrs,        
        
        _EmployeeGroup,
        _EmployeeSubgroup,
        _PersonnelArea,
        _PersonnelSubArea,
        _WorkContract,
        _CostCenter,
        _CostCenter.kosar,
        _CostCenter._CostCenterType,        
        _OrgUnit,
        _Position,
        _Job,
        _Photo
} where sprps = ' '
