var cDoc = Class.create({
    orig: null,
    icons: null,

    initialize: function() {
        /* resize listener */
        window.onresize = AppUtilities.resizeContents;
        AppUtilities.resizeContents();
        console.log('resize set');

        $('search-box').observe('keypress', function(e) {
            if (e.keyCode == 13){
                this.search();
            }
        }.bind(this));

        $('mag').observe('click', function() {
            if ($('search-box').value != ''){
                this.search();
            }
        }.bind(this));


        $$('.buy').each(function(elem){
           elem.observe('click', function(){
                this.purchase(elem.id);
           }.bind(this));
        }.bind(this));

        this.orig = $('search_results').innerHTML;

        this.icons = $('search_json').innerHTML.evalJSON();

    },

    search: function(){
        $('load_search').setStyle({'display': 'block'});
        $('mag').setStyle({'display': 'none'});
        var q = $('search-box').value;
        if(q.length === 0) {
            $('search_results').innerHTML = this.orig;
            $('load_search').setStyle({'display': 'none'});
            $('mag').setStyle({'display': 'block'});
            $$('.buy').each(function(elem){
               elem.observe('click', function(){
                    this.purchase(elem.id);
               }.bind(this));
            }.bind(this));
            return
        }

        var parameters = {};
        parameters['q'] = q;
        new Ajax.Request('/search/full_query', {
           method: 'post',
           parameters: parameters,
           onComplete: function(transport) {
               console.log(transport);
               $('search_json').update(transport.responseText);
               console.log('success');
               $('load_search').setStyle({'display': 'none'});
               $('mag').setStyle({'display': 'block'});
               this.render();
           }.bind(this)
        });
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
                           e.innerHTML = "Purchased";
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
    },

    render: function(){
        var html = '<br/>';
        var results = [];
        $('search_json').innerHTML.evalJSON().collect(function(doc) {
            if(doc['tag']!=null) results.push(doc['tag']);
        });
        console.log(results.length);
        if(results.length === 0){
            console.log('empty');
            html+='<span style="text-align:center; margin:10px; display:block;">No Search Results Found</span>';
        } else {
            html+='';
            i = 1;
            results.each(function(doc){
                html+= "<a href='/store/egg_details/"+doc['id']+"'>\
                <div class='egg_container'>\
                <h4>Aligned StudyEgg for:</h4>\
                <h2>"+doc['name']+"</h2>\
                <img class='egg_image' src='../../images/home/egg.png' />\
                <div class='egg_info'>\
                  <strong>Egg Price: </strong><span class='egg_price'>$29</span><br />\
                  <strong>Lesson Price: </strong><span class='egg_price'>$1</span><br />\
                  <div class='review'><img src='../../images/shared/rating-stars.png' /></div>\
                </div>\
              </div>\
             </a>";
            if(i%3==0){
                html+="<div class='cl'></div>";
            }
            i++;
            });
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