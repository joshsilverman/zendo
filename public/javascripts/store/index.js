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
            if(doc['document']!=null) results.push(doc['document']);
        });
        console.log(results.length);
        if(results.length === 0){
            console.log('empty');
            html+='<span style="text-align:center; margin:10px; display:block;">No Search Results Found</span>';
        } else {
            html+='<div id="carousel-1" class="pluit-carousel big-nav-skin"><div class="viewport"><ul>';
            i = 0;
            results.each(function(doc){
                if(i%5 ==0){
                    html += '<li><ul>';
                }
                html+='<li><div class="egg-box"><a href="store/details/'+doc['id']+'"><div class="egg"><img src="../../images/nounproject/'+this.icons[doc['icon_id']]+'" class="icon"></div></a>'+doc['name']+'<br /></div><li>';
                if(i%5 ==4){
                    html += '</ul></li>';
                }
                i++;
            }.bind(this));
            if(i%5 !=0){
                html += '</ul></li>';
            }
            html +='</ul><br/>';
        }
        $('search_results').update(html);
        new Pluit.Carousel('#carousel-1', {
          circular: true
        });
    }


});

/* global objects */
document.observe('dom:loaded', function() {
    doc = new cDoc;

    /* fire app:loaded */
    document.fire('app:loaded');
});