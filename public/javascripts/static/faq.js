var cDoc = Class.create({

    toggleSwitch: null,

    initialize: function() {
        /* resize listener */
        window.onresize = AppUtilities.resizeContents;
        AppUtilities.resizeContents();
        
        this.toggleSwitch = $('toggle_switch');
    },

    toggleFacts: function() {
        console.log(this.toggleSwitch);
        console.log(this.toggleSwitch.collapsed);
        if (this.toggleSwitch.collapsed == 'false') {
            console.log("1");
            $$(".fact").each(function(fact) {
                fact.hide();
            });
            $$(".heading").each(function(fact) {
                fact.removeClassName("expanded");
            });
            this.toggleSwitch.collapsed = "true"
            this.toggleSwitch.update("Expand All");
        }
        else {
            console.log(this.toggleSwitch);
            $$(".fact").each(function(fact) {
                fact.show();
            });
            $$(".heading").each(function(fact) {
                fact.addClassName("expanded");
            });
            this.toggleSwitch.collapsed = "false"
            this.toggleSwitch.update("Collapse All");
        }
    }
});

/* global objects */
document.observe('dom:loaded', function() {
    doc = new cDoc;

    /* fire app:loaded */
    document.fire('app:loaded');
});