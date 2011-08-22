/* class declarations */

var cDoc = Class.create({

    links: [],

    initialize: function() {
        
        if (window['AppUtilities']) {
            AppUtilities.resizeContents();
        }

        this.links = $$("a");
        this.followLinks();
    },

    followLinks: function() {

        var link = this.links.shift();
        link.up('td').setStyle({"background-color":"blue"});
        $("editor").src = link.href;

        (function() {
            var oDoc = ($("editor").contentWindow || $("editor").contentDocument);
            if (oDoc.document) oDoc = oDoc.document;
            var helperPanelContainer = Element.select(oDoc, '#helper_panel_container');
            if (helperPanelContainer.length > 0) {
                Element.hide(helperPanelContainer[0]);
            }

            oDoc.observe("lookup:idle", function() {
                if (this.links.length) {
                    this.followLinks();
                }
            }.bind(this));
        }.bind(this)).delay(5)
    }
});

/* global objects */
document.observe('dom:loaded', function() {
    doc = new cDoc;

    /* fire app:loaded */
    document.fire('app:loaded');
});
