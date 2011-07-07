var cDoc = Class.create({

    initialize: function() {
        /* resize listener */
        window.onresize = AppUtilities.resizeContents;
        AppUtilities.resizeContents();

        $('search_button').observe('click', function(){
            this.search();
        }.bind(this));

        $('search_bar').observe('focus', function(){
            if($('search_bar').value == 'Search Public Documents') $('search_bar').value = '';
        });

        $('search_bar').observe('blur', function(){
            if($('search_bar').value=='') $('search_bar').value = 'Search Public Documents';
        });
    },

    search: function(){
        $('load_search').setStyle({'visibility': 'visible'});
        var q = $('search_bar').value;
        new Ajax.Request('/search/query/'+q, {
           onComplete: function(transport) {
               console.log(transport.responseText);
               $('search_json').update(transport.responseText);
               console.log('success2');
               $('load_search').setStyle({'visibility': 'hidden'});
               this.render();
           }.bind(this)
        });
    },

    render: function(){
        var html = '<ul>';
        var results = [];
        $('search_json').innerHTML.evalJSON().collect(function(doc) {
            results.push(doc['document']);
        });
        results.each(function(doc){
            html+='<li><a href="documents/'+doc['id']+'">'+doc['name']+'</a></li>';
        });
        html +='</ul>';
        $('search_results').update(html);
    }


});

/* global objects */
document.observe('dom:loaded', function() {
    doc = new cDoc;

    /* fire app:loaded */
    document.fire('app:loaded');
});