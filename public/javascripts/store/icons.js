var cDoc = Class.create({
    active: null,
    doc_id: null,


    initialize: function() {
        this.doc_id = $$('.viewport')[0].id

        new Pluit.Carousel('#carousel-1', {
          circular: true
        });

        $$('.egg').each(function(elem){
            if(elem.hasClassName("selected")){
                this.active = elem;
            }
            elem.observe('click', function(){
            elem.addClassName('selected');
            this.active.removeClassName('selected');
            this.active = elem;
            this.update_icon(elem.id);
        }.bind(this));
        }.bind(this));

    },

    update_icon: function(icon_id){
        var parameters = {};
        parameters['doc_id'] = this.doc_id;
        parameters['icon_id'] = icon_id;
        new Ajax.Request('/documents/update_icon', {
           method: 'post',
           parameters: parameters,
           onComplete: function(transport) {
               console.log(transport.status);
               if( transport.status == 200){
                   $$('.egg').each(function(elem){
                        elem.stopObserving('click');
                        elem.observe('click', function(){
                            elem.addClassName('selected');
                            this.active.removeClassName('selected');
                            this.active = elem;
                        }.bind(this));
                    }.bind(this));
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