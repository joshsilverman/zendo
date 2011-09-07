var cDoc = Class.create({
    next: false,
    back: false,
    p: null,
    size: null,
    typingTimer: setTimeout('', 100),                //timer identifier
    doneTypingInterval: 1000,  //time in ms, 2 second for example


    initialize: function() {
        /* resize listener */
        window.onresize = AppUtilities.resizeContents;
        AppUtilities.resizeContents();
        console.log('resize set');
        $('search_button').observe('click', function(){
            this.search(1);
        }.bind(this));

        $('search_bar').observe('keypress', function(e) {
            if (e.keyCode == 13){
                this.search(1);
            }
        }.bind(this));

        $('search_bar').observe('focus', function(){
            if($('search_bar').value == 'Search Public Study Guides') $('search_bar').value = '';
        });

        $('search_bar').observe('blur', function(){
            if($('search_bar').value=='') $('search_bar').value = 'Search Public Study Guides';
        });

        if(document.getElementById('userfield')!=null){
            $('userfield').observe('keyup', function(){
                clearTimeout(this.typingTimer);
                if($('userfield').value.length != 0){
                    console.log("interval "+this.doneTypingInterval);
                    this.typingTimer = setTimeout(function(){this.checkUsername($('userfield').value);}.bind(this), this.doneTypingInterval);
                    $('submit').setStyle({'display': 'none'});
                    $('taken').setStyle({'display': 'none'});
                    $('available').setStyle({'display': 'none'});
                    $('validate').setStyle({'display':'none'});

                }
            }.bind(this));

            $('submit').observe('click', function(){
                if($('userfield').value.length != 0){
                    this.setUsername($('userfield').value);
                }
            }.bind(this));
        }

    },

    search: function(page){
        $('load_search').setStyle({'display': 'block'});
        var q = $('search_bar').value;
        doc.p=page;
        console.log(doc.p);
        if(q.length === 0) {return};
        var parameters = {};
        parameters['q'] = q;
        new Ajax.Request('/search/query/'+page, {
           method: 'post',
           parameters: parameters,
           onComplete: function(transport) {
               console.log(transport);
               console.log(transport.responseText);
               $('search_json').update(transport.responseText);
               console.log('success2');
               $('load_search').setStyle({'display': 'none'});
               this.render();
           }.bind(this)
        });
    },

    checkUsername: function(username){
        var u = $('userfield').value;
        if(u.length === 0) {
            $('validate').setStyle({'display':'block'});
            $('taken').setStyle({'display': 'none'});
            $('available').setStyle({'display': 'none'});
            $('submit').setStyle({'display': 'none'});
            return
        };
        var regex = /^\w+[^\s]\w+$/.test(u);
        console.log(u);
        if(u.length<3 || u.length>20 || !regex ){
            $('validate').setStyle({'display':'block'});
            $('taken').setStyle({'display': 'none'});
            $('available').setStyle({'display': 'none'});
            $('submit').setStyle({'display': 'none'});
        } else {
            var parameters = {};
            parameters['u'] = u;
            new Ajax.Request('/search/is_username_available', {
               method: 'post',
               parameters: parameters,
               onComplete: function(transport) {
                   console.log("Is it available? "+transport.responseText);
                   if(transport.responseText=='true'){
                        console.log('evaluated as true');
                        $('validate').setStyle({'display':'none'});
                        $('taken').setStyle({'display': 'none'});
                        $('available').setStyle({'display': 'inline'});
                        $('submit').setStyle({'display': 'inline'});
                   } else {
                        console.log('false');
                        $('validate').setStyle({'display':'none'});
                        $('taken').setStyle({'display': 'inline'});
                        $('available').setStyle({'display': 'none'});
                        $('submit').setStyle({'display': 'none'});
                   }
                   console.log('success2');
               }
            });
        }
    },

    setUsername: function(username){
        var u = $('userfield').value;
        if(u.length === 0) {
            $('taken').setStyle({'display': 'none'});
            $('available').setStyle({'display': 'none'});
            $('submit').setStyle({'display': 'none'});
            return
        };
        var parameters = {};
        parameters['u'] = u;
        new Ajax.Request('/users/update_username', {
           method: 'post',
           parameters: parameters,
           onComplete: function(transport) {
               if(transport.status == 200){
                Lightview.hide();
                console.log('success2');
               } else {
                   alert('there was an error with your screen name');
               }
           }
        });
    },

    render: function(){
        this.back=false;
        this.front=true;
        console.log(doc.p);
        var html = '';
        var results = [];
        $('search_json').innerHTML.evalJSON().collect(function(doc) {
            if(doc['document']!=null) results.push(doc['document']);
            if(doc['size']!=null) this.size = doc['size'];
        });
        console.log(results.length);
        if(results.length === 0){
            console.log('empty');
            html+='<span style="text-align:center; margin:10px; display:block;">No Search Results Found</span>';
        } else {
            var pagemax = (parseInt(this.size)-(parseInt(this.size)%5))/5;
            if(parseInt(this.size)%5!=0) pagemax++;
            console.log(pagemax);
            html+='<ul>';
            results.each(function(doc){
                html+='<li><a href="documents/'+doc['id']+'">'+doc['name']+' (<em>'+doc['tag_name']+'</em>)</a></li>';
            });
            html +='</ul><br/>';
            if(doc.p==1){
                this.back=false;
            } else { 
                this.back=true;
            }

            if(doc.p==pagemax){
                this.next=false;
            } else { 
                this.next=true;
            }
            console.log(this.next);
            if(this.back){
                html+='<span id="back_button" onClick="doc.search('+(parseInt(doc.p)-1)+')"><< Back  </span>';
            }
            if(this.next){
                html+='<span id="next_button" onClick="doc.search('+(parseInt(doc.p)+1)+')">  Next >></span>';
            }
        }
        $('search_results').update(html);
    }.bind(this)


});

/* global objects */
document.observe('dom:loaded', function() {
    doc = new cDoc;

    /* fire app:loaded */
    document.fire('app:loaded');
});

document.observe('lightview:loaded', function() {

    if(document.getElementById('userfield')!=null){
      Lightview.show({
        href: 'username',
        rel: 'inline',
    //    title: 'Choose a Username',
    //    caption: 'Don\'t worry, you can always change it later',
        options: {
          width: 400,
          height: 220,
          overlayClose: false,
          closeButton: false
        }
      });
    }
});