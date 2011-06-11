var cDoc = Class.create({

    toggleSwitch: null,

    initialize: function() {
        /* resize listener */
        window.onresize = AppUtilities.resizeContents;
        AppUtilities.resizeContents();


        this.toggleSwitch = $('toggle_switch');

        $$('.heading span').each(function(heading) {
            heading.observe('click', this.toggleFact.curry(heading.up('.fact-wrapper'), null));
        }.bind(this));
    },

    toggleFact: function(factWrapper, collapsed) {
        var fact = factWrapper.select('.fact')
        var heading = factWrapper.select('.heading span')
        if (fact.length > 0 && heading.length > 0) {
            fact = fact[0];
            heading = heading[0];
        }
        else {
            console.log("couldn't find elements");
            return;
        }


        if (fact.collapsed == 'false' && collapsed === null || collapsed) {
            fact.hide();
            heading.removeClassName("expanded");
            fact.collapsed = "true"
        }
        else {
            fact.show();
            heading.addClassName("expanded");
            fact.collapsed = "false"
        }
    },

    toggleFacts: function() {

        if (this.toggleSwitch.collapsed == 'false') {
            this.toggleSwitch.collapsed = "true"
            this.toggleSwitch.update("Expand All");
        }
        else {
            this.toggleSwitch.collapsed = "false"
            this.toggleSwitch.update("Collapse All");
        }
        $$(".fact-wrapper").each(function(factWrapper) {
            this.toggleFact(factWrapper, this.toggleSwitch.collapsed == 'true');
        }.bind(this));
    }
});

/* global objects */
document.observe('dom:loaded', function() {
    doc = new cDoc;

    /* fire app:loaded */
    document.fire('app:loaded');
});