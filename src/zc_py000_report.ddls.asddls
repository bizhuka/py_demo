@AbapCatalog.sqlViewName: 'zvcpy000_report'
@AbapCatalog.compiler.compareFilter: true
@AbapCatalog.preserveKey: true
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'PY Demo report'
@Search.searchable

@OData.publish: true

@ZABAP.virtualEntity: 'ZCL_PY000_REPORT'

@UI: {
    headerInfo: {
        typeName: 'Employee',
        typeNamePlural: 'Employees count',
        title: {
            type: #STANDARD, value: 'ename'
        },
        description: {
            value: 'pernr'
        }
    }
}  
define view ZC_PY000_REPORT as select from ZC_PY000_OrgAssignment as _main

association [0..*] to ZC_PY000_REPORT_RT as _RT_SUM_1 on _RT_SUM_1.pernr      = _main.pernr
                                                     and _RT_SUM_1.key_date   = _main.datum
                                                     and _RT_SUM_1.field_name = 'SUM_1'
                                                     
association [0..*] to ZC_PY000_REPORT_RT as _RT_SUM_2 on _RT_SUM_2.pernr      = _main.pernr
                                                     and _RT_SUM_2.key_date   = _main.datum
                                                     and _RT_SUM_2.field_name = 'SUM_2'
{
        @UI.lineItem: [{ position: 10 }]
        @Search: { defaultSearchElement: true, fuzzinessThreshold: 0.7 } 
        key pernr,
        
        @UI.lineItem: [{ position: 20 }]
        key begda,
        
        @UI.lineItem: [{ position: 30 }]
        key endda,
        
        // Current date  @UI.selectionField: [{ position: 5 }]
        //@Consumption.filter: { selectionType: #INTERVAL, multipleSelections: false } // , mandatory: true
        key datum as key_date,
        
        @Search: { defaultSearchElement: true, fuzzinessThreshold: 0.8 }
        @UI.lineItem: [{ position: 40 }]
        ename,
       
        
        @UI.selectionField: [{ position: 10 }]
        @UI.lineItem: [{ position: 50 }]
        @ObjectModel.text.element: [ 'persg_txt' ]
        persg,
        _EmployeeGroup.ptext as persg_txt,
        
        @UI.selectionField: [{ position: 20 }]
        @UI.lineItem: [{ position: 60 }]
        @ObjectModel.text.element: [ 'persk_txt' ]
        persk,
        _EmployeeSubgroup.ptext as persk_txt,
        
        @UI.selectionField: [{ position: 30 }]
        @UI.lineItem: [{ position: 70 }]
        @ObjectModel.text.element: [ 'persa_txt' ]
        persa,
        _PersonnelArea.name1 as persa_txt,
        
        @UI.selectionField: [{ position: 40 }]
        @UI.lineItem: [{ position: 80 }]
        @ObjectModel.text.element: [ 'btrtl_txt' ]
        btrtl,
        _PersonnelSubArea.btext as btrtl_txt,
        
        kokrs,
        @UI.selectionField: [{ position: 50 }]
        @UI.lineItem: [{ position: 90 }]
        @ObjectModel.text.element: [ 'kostl_txt' ]
        kostl,
        _CostCenter.ltext as kostl_txt,
        
        @UI.selectionField: [{ position: 45 }]
        ansvh,
        
        @UI.selectionField: [{ position: 60 }]       
        orgeh,        

        plans,        
        stell,        
        bukrs,   
        
        @EndUserText.label: 'WT 1*'
        @UI.lineItem: [{ position: 100, importance: #HIGH }]
        cast( 0 as abap.curr( 15, 2 ) ) as sum_1,
        
        @EndUserText.label: 'WT 2*'
        @UI.lineItem: [{ position: 110, importance: #HIGH }]
        cast( 0 as abap.curr( 15, 2 ) ) as sum_2,
        
        // Avatar
        concat( concat('../../../../../opu/odata/sap/ZC_PY000_REPORT_CDS/ZC_PY000_PernrPhoto(pernr=''', pernr),
               ''')/$value')  as photo_path,     
        
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
        _Photo,
        
        _RT_SUM_1,
        _RT_SUM_2
}
