var cDoc = Class.create({
    next: false,
    back: false,
    p: null,
    size: null,
    orig: null,

    initialize: function() {

        $$('.buy').each(function(elem){
           elem.observe('click', function(){
                this.purchase(elem.id);
           }.bind(this));
        }.bind(this));

        window.onresize = AppUtilities.resizeContents;
        AppUtilities.resizeContents();

    },

    purchase: function(id){
        var parameters = {};
        parameters['doc_id'] = id;
        new Ajax.Request('/documents/purchase_doc/', {
           method: 'post',
           parameters: parameters,
           onComplete: function(transport) {
               console.log(transport.status);
               if( transport.status == 200){
                   $$('.buy').each(function(e){
                       if(e.id == id){
                           e.innerHTML = "<img src='../../images/home/purchased.png' />";
                           e.removeClassName('buy');
                           e.addClassName('purchased');
                           e.stopObserving('click');
                       }
                   });
//                   $(id).innerHTML = "Purchased";
//                   $(id).removeClassName('buy');
//                   //$(id).addClassName('purchased');
//                   $(id).stopObserving('click');
               }
           }.bind(this)
        });
    }

});

/* global objects */
document.observe('dom:loaded', function() {
    doc = new cDoc;

    /* fire app:loaded */
    document.fire('app:loaded');
});