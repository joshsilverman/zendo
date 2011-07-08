var cDoc = Class.create({

    initialize: function() {
        /* resize listener */
        window.onresize = AppUtilities.resizeContents;
        AppUtilities.resizeContents();

        $('search_button').observe('click', function(){
            this.search();
        }.bind(this));

        $('search_bar').observe('keypress', function(e) {
            if (e.keyCode == 13) this.search();
        }.bind(this));

        $('search_bar').observe('focus', function(){
            if($('search_bar').value == 'Search Public Study Guides') $('search_bar').value = '';
        });

        $('search_bar').observe('blur', function(){
            if($('search_bar').value=='') $('search_bar').value = 'Search Public Study Guides';
        });
    },

    search: function(){
        $('load_search').setStyle({'display': 'block'});
        var q = $('search_bar').value;
        if(q.length === 0) {return};
        new Ajax.Request('/search/query/'+q, {
           onComplete: function(transport) {
               console.log(transport.responseText);
               $('search_json').update(transport.responseText);
               console.log('success2');
               $('load_search').setStyle({'display': 'none'});
               this.render();
           }.bind(this)
        });
    },

    render: function(){
        var html = '';
        var results = [];
        $('search_json').innerHTML.evalJSON().collect(function(doc) {
            results.push(doc['document']);
        });
        if(results.length === 0){
            console.log('empty');
            html+='<span style="text-align:center; margin:10px; display:block;">No Search Results Found</span>';
        } else {
            console.log('not empty');
            html+='<ul>';
            results.each(function(doc){
                html+='<li><a href="documents/'+doc['id']+'">'+doc['name']+'</a></li>';
            });
            html +='</ul>';
        }
        $('search_results').update(html);
    }


});

/* global objects */
document.observe('dom:loaded', function() {
    doc = new cDoc;

    /* fire app:loaded */
    document.fire('app:loaded');
});