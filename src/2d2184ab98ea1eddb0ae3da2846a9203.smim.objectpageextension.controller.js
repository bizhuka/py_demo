sap.ui.controller("zpy000.ext.controller.ObjectPageExtension", {

	_prefix: 'zpy000::sap.suite.ui.generic.template.ObjectPage.view.Details::ZC_PY000_REPORT--',


	onInit: function () {
		window._objectPage = this

		const _view = this.getView()
		const objectPage = _view.byId(this._prefix + "objectPage")
		if (objectPage)
			objectPage.setUseIconTabBar(true)
	},

	onAfterRendering: function () {
		this.readCurrentPerson()
	},

	_refreshCalendar: function () {
		this._oModel.updateBindings()
	},

	readCurrentPerson: function (nPernr) {
		if (!nPernr) {
			const urlPart = "pernr='"
			const iFrom = window.location.href.indexOf(urlPart)
			nPernr = window.location.href.substring(iFrom + urlPart.length, iFrom + urlPart.length + 8)
		}
	}
});
