sap.ui.controller("zpy000.ext.controller.ListReportExtension", {

  _prefix: 'zpy000::sap.suite.ui.generic.template.ListReport.view.ListReport::ZC_PY000_REPORT--',

  onInit: function () {
    const keyDate = this.getCookie('KeyDate')
    this.getView().byId('dpKeyDate').setValue(this.getDateIso(keyDate ? new Date(keyDate) : new Date()))

    const listReportFilter = this.getView().byId(this._prefix + 'listReportFilter')
    listReportFilter.setLiveMode(true)
    listReportFilter.setShowClearOnFB(true)
  },

  getCookie: function (name) {
    const value = `; ${document.cookie}`;
    const parts = value.split(`; ${name}=`);
    if (parts.length === 2) return parts.pop().split(';').shift();
  },

  onBeforeRebindTableExtension: function (oEvent) {
    var oBindingParams = oEvent.getParameter("bindingParams");
    oBindingParams.parameters = oBindingParams.parameters || {};

    var oSmartTable = oEvent.getSource();
    var oSmartFilterBar = this.byId(oSmartTable.getSmartFilterId());

    if (!oSmartFilterBar instanceof sap.ui.comp.smartfilterbar.SmartFilterBar)
      return

    var oCustomControl = oSmartFilterBar.getControlByKey("cfKeyDate");
    if (!oCustomControl instanceof sap.m.Switch)
      return

    const keyDate = oCustomControl.getValue()
    document.cookie = 'KeyDate=' + keyDate + '; max-age=3600; path=/';

    const datum = this.getDateIso(new Date(keyDate))
    oBindingParams.filters.push(new sap.ui.model.Filter("key_date", "EQ", datum))
  },

  onListNavigationExtension: function (oEvent) {
    //var oNavigationController = this.extensionAPI.getNavigationController()
    const obj = oEvent.getSource().getBindingContext().getObject()
    if (window._objectPage)
      window._objectPage.readCurrentPerson(obj.pernr)

    // return false to trigger the default internal navigation
    return false
  },

  // TODO make lib
  getDateIso: function (date) {
    const okDate = new Date(date.getTime() - (date.getTimezoneOffset() * 60 * 1000))
    return okDate.toISOString().split('T')[0]
  },

  onAfterRendering: function (oEvent) {
    this._setMessageParser()
    this._initReportMenu()
  },

  _setMessageParser: function () {
    const _view = this.getView()
    const model = _view.getModel()
    sap.ui.require(["zpy000/ext/controller/MessageParser"], function (MessageParser) {
      const messageParser = new MessageParser(model.sServiceUrl, model.oMetadata, !!model.bPersistTechnicalMessages)
      model.setMessageParser(messageParser)
    })
  },

  _initReportMenu: function () {
    const _this = this
    const _view = _this.getView()

    const menuId = _this._prefix + 'report-xlsx'
    if (_view.byId(menuId))
      return

    const params = {
      id: menuId,
      text: "Report",
      icon: "sap-icon://excel-attachment",

      press: function () {
        const table = _view.byId(_this._prefix + 'responsiveTable')
        const sFilter = table.getBinding("items").sFilterParams

        const decodedFilter = decodeURIComponent(sFilter)
        if (decodedFilter.indexOf("and key_date eq datetime'") === -1) {
          sap.m.MessageToast.show('Please specify at least one filter except obligatory', { duration: 3500 })
          $(".sapMMessageToast").css("background", "#cc1919");
          return
        }

        sap.ui.require(["zpy000/ext/controller/ReportDialog"], function (ReportDialog) {
          if (!_this.reportDialog)
            _this.reportDialog = new ReportDialog()
          _this.reportDialog.initDialog(_this, sFilter)
          _this.reportDialog.dialog.open();
        })
      }
    }

    const baseMenu = _view.byId(this._prefix + 'listReport-btnExcelExport')
    if (baseMenu)
      baseMenu.getMenu().addItem(new sap.m.MenuItem(params))
    else  // For sapui5 1.71
      _view.byId(_this._prefix + 'template::ListReport::TableToolbar').addContent(new sap.m.Button(params))
  },

  onInitSmartFilterBarExtension: function (oEvent) {
    // moded to CDS
    // const _filterBar = oEvent.getSource()
    // const filterData = _filterBar.getFilterData()
    // filterData.persa = {items: [{ key: "1010",text: "Field - 1010"}]}
    // _filterBar.setFilterData(filterData)

    // Hide variant selection
    this.getView().byId(this._prefix + 'template:::ListReportPage:::DynamicPageTitle').setVisible(false)
  }
});