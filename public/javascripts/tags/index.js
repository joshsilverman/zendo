/* class declarations */

var cDoc = Class.create({

    /* parsed tag info */
    tags: null,
    docs: null,
    html: null,
    theDate: null,
    activeItemId: '',


    initialize: function() {
        /* organize and set json member */
        this.tags = [];
        $('tags_json').innerHTML.evalJSON().collect(function(tag) {
            this.tags.push(tag['tag']);
        }.bind(this));

        //set all documents
        this.docs = new Hash();
        this.tags.each(function(tag){
            tag['documents'].each(function(doc){
                this.docs.set(doc['id'], doc);
            }.bind(this));
        }.bind(this));

        /* resize listener */
        window.onresize = AppUtilities.resizeContents;
    },

    onChange: function(){
        this.render();
    },

    _buildFolders: function(){
        var html = '';
        this.tags.each(function(tag) {
          html += '<h2 tag_id="'+tag['id']+'" class="accordion_toggle collapse">'+tag['name']+'</h2>\
              <div id="accordion_content_'+tag['id']+'" class="accordion_content" tag_id="'+tag['id']+'" ></div>';
        }.bind(this));
        $('documents').update(html);
    },

    _buildDocs: function(){
        var html = '';
        this.tags.each(function(tag) {
          tag['documents'].each(function(doc){
              //this.docs.set(doc['id'], doc);
              html += '<div class="doc_item inactive" doc_id="'+doc['id']+'">\
                    <input type="checkbox" class="chbox" doc_id="'+doc['id']+'"/>\
                    <span class="doc_title" doc_id="'+doc['id']+'">'+doc['name']+'</span>\
                    <div class="doc_actions">\
                    <ul><li><a href="/documents/'+doc['id']+'/edit">edit</a></li>\
                    <li><a href="/review/'+doc['id']+'">review</a></li>\
                    <li><span class="remove_doc" doc_id="'+doc['id']+'">delete</span></li>\
                    </ul>\
                    </div>\
                    </div>';
          });
          var elemId = 'accordion_content_'+tag['id'];
          $(elemId).update(html);
          html='';
        }.bind(this));
    },

    _buildDetails: function(){
        var html = '';
        var checkedList = [];
        $$('.chbox').each(function(ele){
           if( $(ele).checked )
           {
               checkedList.push($(ele).getAttribute('doc_id'));
           }
        });
        if(checkedList[0] == null){
            html += '<em>Click a checkbox to view document details...</em>';
        } else if(checkedList[1] == null){
            var singleDoc = this.docs.get(checkedList[0]);
            this.convertDate(new Date(singleDoc['created_at']));
            var created = this.theDate;
            this.convertDate(new Date(singleDoc['updated_at']));
            var updated = this.theDate;
            html += '<div id="metainfo" doc_id="'+checkedList[0]+'"><div id="sdt" class="single_doc_title"><div class="edit_icon"><span id="detail_name"><em>'+singleDoc['name']+'</em></span></div></div>\
                    <div style="clear: both;"></div><h4 class="details_label">Created On: </h4>\
                    <em>'+created+'</em><br/>\
                    <h4 class="details_label">Last Updated: </h4>\
                    <em>'+updated+'</em></div>';
        } else {
            html+='<div id="metainfo"><h4 class="details_label">Multiple Documents:</h4>';
            var multiDoc = [];
            var i=0;
            while(checkedList[i]!=null){
                multiDoc.push(this.docs.get(checkedList[i]));
                i+=1;
            }

            multiDoc.each(function(item){
                html += '<br/><em>'+item['name']+'</em>';
            });
            html+= '</div>';
        }
        $('details').update(html);

        //listener for doc name change
        $$('.single_doc_title').each(function(elem){
            elem.observe('click', function(event) {
                var title = event.target.innerHTML;
                event.target.innerHTML = '<input id="edt" class="edit_doc_title" value="'+title+'" />';
                $('edt').focus();
                $$('.edit_doc_title').each(function(elem){
                    elem.observe('keypress', function(e) {
                        if (e.keyCode == 13) e.target.blur();
                    }.bind(this));

                    elem.observe('blur', function(){
                        var newTitle = $('edt').value;
                        $('sdt').innerHTML = '<div class="edit_icon"><span id="detail_name"><em>'+newTitle+'</em></span></div>';
                        //add save call
                    }.bind(this));
                }.bind(this));
            }.bind(this));
        }.bind(this));
    },

    

    sameHeight: function(){
        var h = $('documents').getHeight();
        h += 50;
        $('documents').setStyle({height: h + 'px'});
        $('details').setStyle({height: h + 'px'});
    },

    convertDate: function(d){
        var m_names = new Array("January", "February", "March",
        "April", "May", "June", "July", "August", "September",
        "October", "November", "December");

        var curr_date = d.getDate();
        var sup = "";
        if (curr_date == 1 || curr_date == 21 || curr_date ==31)
           {
           sup = "st";
           }
        else if (curr_date == 2 || curr_date == 22)
           {
           sup = "nd";
           }
        else if (curr_date == 3 || curr_date == 23)
           {
           sup = "rd";
           }
        else
           {
           sup = "th";
           }

        var curr_month = d.getMonth();
        var curr_year = d.getFullYear();

        this.theDate = (m_names[curr_month] +" "+ curr_date + "<sup>" + sup + "</sup> " + " " + curr_year);
    },

    render: function(){
        this._buildFolders();
        this._buildDocs();
        this._buildDetails();
        this.sameHeight();

        //Add Listeners

        //click doc name link
        $$('.doc_title').each(function(element) {
            element.observe('click', function(event) {
            var docId = event.target.getAttribute('doc_id');
            /* review document */
            this.reviewDocument(docId);
            event.stop();
            }.bind(this));
        }.bind(this));

        //remove document
        $$('.remove_doc').each(function(element) {
            element.observe('click', this.destroyDocument.bind(this));
        }.bind(this));

        //click doc item to reveal actions and highlight with css

        $$('.doc_item').each(function(element) {
            element.observe('click', function(event) {
            if(event.target.getAttribute('class')=='doc_item active' || event.target.getAttribute('class')=='doc_item inactive'){
            if(this.activeItemId==''){ //if nothing is open
                event.target.down(2).setStyle({display:'block'});
                this.activeItemId = event.target.getAttribute('doc_id');
                event.target.removeClassName('inactive');
                event.target.addClassName('active');
                event.stop();
            } else if(this.activeItemId==event.target.getAttribute('doc_id')) { //if you reclick an open item
                event.target.down(2).setStyle({display:'none'});
                this.activeItemId = '';
                event.target.removeClassName('active');
                event.target.addClassName('inactive');
                event.stop();
            } else { //if you switch open items
                var openAction = $('documents').getElementsBySelector( 'div.doc_item[doc_id="'+this.activeItemId+'"]');
                openAction[0].down(2).setStyle({display:'none'});
                event.target.down(2).setStyle({display:'block'});
                event.target.removeClassName('inactive');
                event.target.addClassName('active');
                openAction[0].removeClassName('active');
                openAction[0].addClassName('inactive');
                this.activeItemId = event.target.getAttribute('doc_id');
                event.stop();
            }
            }
            }.bind(this));
        }.bind(this));

        //listen for checkboxes
        $$('.chbox').each(function(element) {
            element.observe('click', function(event) {
                this._buildDetails();
                }.bind(this));
        }.bind(this));

        //listen for folder click
        $$('.accordion_toggle').each(function(element){
            element.observe('click', function(event){
                new Effect.toggle(event.target.next(0),'Blind', {duration:.5});
                if(event.target.className =='accordion_toggle collapse'){
                    event.target.removeClassName('collapse');
                    event.target.addClassName('expand');
                } else {
                    event.target.removeClassName('expand');
                    event.target.addClassName('collapse');
                }
            })
        }.bind(this));
    },

    destroyDocument: function(event) {

        /* confirm */
        if (!confirm('Are you sure you want to delete this document? This cannot be undone.')) return;

        /* request params */
        var documentId = event.target.getAttribute('doc_id');

        /* request */
        new Ajax.Request('/documents/' + documentId, {
            method: 'delete',
            onSuccess: function(transport) {

                /* inject json and rerender document */
                $('tags_json').update(Object.toJSON(transport.responseJSON));
                doc = new cDoc;
                doc.onChange();
            }.bind(this),
            onFailure: function(transport) {
                alert('There was an error removing the directory.');
            }
        });
    },

    reviewDocument: function(docId){
        /* new document */
        self.document.location.href = '/review/' + docId
    },

    destroyFolder: function(){
        //Fill out
    }

});

/* global objects */
document.observe('dom:loaded', function() {
    doc = new cDoc;
    doc.onChange();

    /* fire app:loaded */
    document.fire('app:loaded');
});