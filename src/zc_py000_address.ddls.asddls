@AbapCatalog.sqlViewName: 'zvcpy000_addr'
@AbapCatalog.compiler.compareFilter: true
@AbapCatalog.preserveKey: true
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Address'


define view ZC_PY000_Address as select from pa0006 as _main

association [0..1] to ZC_PY000_Country as _Country on _Country.land1 = _main.land1

association [0..1] to ZC_PY000_Region  as _Region on _Region.land1 = _main.land1
                                                 and _Region.bland = _main.state 
{
         key pernr,
         key begda,
         key endda,
         key subty,
            
            @UI.fieldGroup: [{ qualifier: 'Address', position: 10, label: 'Country' }]
            @ObjectModel.text.element: [ 'landx' ] 
            land1,
            
            @Consumption.valueHelp: '_Region' 
            @ObjectModel.text.element: [ 'bezei' ]
            @UI.fieldGroup: [{ qualifier: 'Address', position: 20 }]
            state,
            
            @UI.fieldGroup: [{ qualifier: 'Address', position: 30 }]
            ort01,
            @UI.fieldGroup: [{ qualifier: 'Address', position: 31 }]
            ort02,
            
            @UI.fieldGroup: [{ qualifier: 'Address', position: 40 }]
            stras,
            @UI.fieldGroup: [{ qualifier: 'Address', position: 50, label: 'House Number' }]
            cast (hsnmr as abap.char( 10 ) ) as hsnmr,
            @UI.fieldGroup: [{ qualifier: 'Address', position: 60, label: 'Apartment ID'}]
            cast (posta as abap.char( 10 ) ) as posta, 
            
            @UI.fieldGroup: [{ qualifier: 'Address', position: 70}]
            telnr,           
            
            _Country,
            _Region
} where sprps = ' '
