/* class declarations */

var cDoc = Class.create({

    classSelector: null,

    /* parsed tag info */
    tags: null,
    docs: null,
    html: null,
    theDate: null,
    activeTags: null,
    activeItemId: '',
    h: null,

    initialize: function() {
        this.prepareData();
        window.onresize = AppUtilities.resizeContents;
        AppUtilities.resizeContents();

        /* load class selecter widget - must be done here also in case nothing is selected */
        this.classSelector = new cClassSelector(true);
    },

    prepareData: function() {
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

        if(this.activeTags==null){
            this.activeTags = new Hash();
            var activeT = this.activeTags;
            this.tags.each(function(tag){
                activeT.set(tag['id'], 'open');
            });
        }
        /* resize listener */
        AppUtilities.resizeContents();
    },

    onChange: function(){
        this.render();
    },

    _buildFolders: function(){
        var html = '';
        this.tags.each(function(tag) {
          var icon = 'expand';
          var style = 'style= "display:none;"';
          if(this.activeTags.get(tag['id'])=='open'){
              icon = 'collapse';
              style='style="display:block;"';
          }
          html += '<div class="accordion_toggle rounded_border '+icon+'" tag_id="'+tag['id']+'" >'+tag['name']+'\
              <img id="delete_'+tag['id']+'" class="remove_folder_icon" src="../../images/organizer/remove-icon-bw-15x15.png" style="display:none;"/>\
              <img id="edit_'+tag['id']+'" class="edit_folder_icon" src="../../images/organizer/edit-icon-bw-15x15.png" style="display:none;"/></div><div style="clear:both;"></div>\
              <div id="accordion_content_'+tag['id']+'" class="accordion_content" tag_id="'+tag['id']+'" '+style+'></div>';
        }.bind(this));
        $('documents').update(html);

    },

    _buildDocs: function(){
        var html = '';
        this.tags.each(function(tag) {
          var active = this.activeItemId;
          tag['documents'].each(function(doc){
              //this.docs.set(doc['id'], doc);
              if(doc['id']==active){
                  html+= '<div class="doc_item active" doc_id="'+doc['id']+'">\
                    <input type="checkbox" class="chbox" doc_id="'+doc['id']+'"/>\
                    <span class="doc_title" doc_id="'+doc['id']+'">'+doc['name']+'</span>\
                    <div class="doc_actions" style="display:block;">\
                    <ul><li><a href="/documents/'+doc['id']+'/edit"><img class="doc_action_img" src="../../images/organizer/edit-icon-15x15.png">edit</a></li>\
                    <li><a href="/review/'+doc['id']+'"><img class="doc_action_img" src="../../images/organizer/review-icon.png">review</a></li>\
                    <li><span class="remove_doc" doc_id="'+doc['id']+'"><img class="doc_action_img" doc_id="'+doc['id']+'" src="../../images/organizer/remove-icon-15x15.png">delete</span></li></ul>\
                    </div>\
                    </div>';
              } else {
              html += '<div class="doc_item inactive" doc_id="'+doc['id']+'">\
                    <input type="checkbox" class="chbox" doc_id="'+doc['id']+'"/>\
                    <span class="doc_title" doc_id="'+doc['id']+'">'+doc['name']+'</span>\
                    <div class="doc_actions">\
                    <ul><li><a href="/documents/'+doc['id']+'/edit"><img class="doc_action_img" src="../../images/organizer/edit-icon-15x15.png">edit</a></li>\
                    <li><a href="/review/'+doc['id']+'"><img class="doc_action_img" src="../../images/organizer/review-icon.png">review</a></li>\
                    <li><span class="remove_doc" doc_id="'+doc['id']+'"><img class="doc_action_img" doc_id="'+doc['id']+'" src="../../images/organizer/remove-icon-15x15.png">delete</span></li></ul>\
                    </div>\
                    </div>';
              }
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
        if(checkedList[0] == null && this.activeItemId==''){
            html += '<span id="create_folder">Create New Folder</span>\
                    <span style="text-align:center; display:block; margin:10px 0">- OR -</span>\
                    <em style="text-align:center; display:block;" >Select a document to view details...</em>';
        } else if((checkedList[0] == null && this.activeItemId!='')||(checkedList[1] == null && this.activeItemId!='')){
            var singleDoc = this.docs.get(this.activeItemId);
            this.convertDate(new Date(singleDoc['created_at']));
            var created = this.theDate;
            this.convertDate(new Date(singleDoc['updated_at']));
            var updated = this.theDate;
            var selector ='<select id="tag_id" class="selector">';
            this.tags.each(function(t){
                var s = ''
                if(t['id']==singleDoc['tag_id']) {s = 'selected = "selected"';}
                selector +='<option value="'+t['id']+'" '+s+'>'+t['name']+'</option>';
            });
            selector += '</select>';
            
            html += '<div id="metainfo" doc_id="'+this.activeItemId+'">\
                    '+selector+'<img alt="loading" id="doc_loading" src="../../images/shared/fb-loader.gif" style="margin-right:5px;visibility:hidden;">\
                    <img class="elbow" src="../../images/organizer/elbow-icon.png"/><div id="sdt" class="single_doc_title"><span id="detail_name">'+singleDoc['name']+'</span></div>\
                    <div style="clear: both;"></div><h4 class="details_label">Created On: </h4>\
                    <em>'+created+'</em><br/>\
                    <h4 class="details_label">Last Updated: </h4>\
                    <em>'+updated+'</em></div>';
        } else if(checkedList[1] == null && this.activeItemId == ''){
            html += 'You have selected <strong>'+this.docs.get(checkedList[0])['name']+'</strong>... Use the checkboxes to take actions on multiple documents';
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
        
        if(checkedList[0] == null && this.activeItemId==''){
           $('create_folder').observe('click', function(event){
               $('new_folder_menu').show();
            }.bind(this)); 
        }

        this.resizeDetails();

        /* load class selecter widget */
        this.classSelector = new cClassSelector(true);

        //listener for doc name change
        $$('.single_doc_title').each(function(elem){
            elem.observe('click', function(event) {
                event.target.stopObserving();
                var title = $('sdt').down(0).innerHTML;
                $('sdt').innerHTML = '<input id="edt" class="edit_doc_title" value="'+title+'" />';
                $('edt').focus();
                $$('.edit_doc_title').each(function(elem){
                    elem.observe('keypress', function(e) {
                        if (e.keyCode == 13) e.target.blur();
                    }.bind(this));

                    elem.observe('blur', function(){
                        console.log('blur start');
                        var newTitle = $('edt').value;
                        if(!(newTitle==title)){
                        var parameters = {};
                        parameters['doc_id'] = $('metainfo').getAttribute('doc_id');
                        parameters['name'] = newTitle;
                        console.log('params set');
                        new Ajax.Request('/documents/update_document_name', {
                            method: 'post',
                            parameters: parameters,
                            onFailure: function() {
                                console.log('FAIL');
                            },
                            onSuccess: function() {
                                console.log('SUCCESS');
                                new Ajax.Request('/tags/get_tags_json', {
                                   onSuccess: function(transport) {
                                       console.log('SUCCESS 2');
                                       $('tags_json').update(transport.responseText);
                                       this.prepareData();
                                       this.render();
                                       console.log('finished');
                                   }.bind(this)
                                });
                            }.bind(this)
                        });
                        } else {this._buildDetails();}
                    }.bind(this));
                }.bind(this));
            }.bind(this));
        }.bind(this));
    },

    resizeDetails: function(){
        this.h = $('documents').getHeight();
        $('details').setStyle({height: (this.h - 88)+'px'});
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

    destroyFolder: function(event){
        if (!confirm('Are you sure you want to delete this directory and all of it\'s contents? This cannot be undone.')) return;
        /* request */
        var tagId = event.target.getAttribute('id');
        tagId = tagId.substring(7);
        console.log(tagId);
        new Ajax.Request('/tags/' + tagId, {
            method: 'delete',
            onSuccess: function(transport) {

                /* inject json and rerender document */
                $('tags_json').update(transport.responseText);
                this.prepareData();
                console.log('prepped');
                this.render();
                console.log('render');
            }.bind(this),
            onFailure: function(transport) {
                alert('There was an error removing the directory.');
            }
        });
    },

    renameFolder: function(event){

        /* request params */
        var tagName = prompt('What would you like to rename this directory?');
        if (!tagName) return;

        
        var parameters = {};
        var tag_id = event.target.getAttribute('id');
        parameters['tag_id'] = tag_id.substring(5);
        parameters['name'] = tagName;
        console.log('params set');
        new Ajax.Request('/tags/update_tags_name', {
            method: 'post',
            parameters: parameters,
            onFailure: function() {
                console.log('FAIL');
            },
            onSuccess: function() {
                console.log('SUCCESS');
                new Ajax.Request('/tags/get_tags_json', {
                   onSuccess: function(transport) {
                       console.log('SUCCESS 2');
                       $('tags_json').update(transport.responseText);
                       this.prepareData();
                       this.render();
                       console.log('finished');
                   }.bind(this)
                });
            }.bind(this)
        });
    },

    render: function(){
        this._buildFolders();
        this._buildDocs();
        this._buildDetails();
        this.resizeDetails();
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
            this._buildDetails();
            }.bind(this));
        }.bind(this));

        //listen for checkboxes
        $$('.chbox').each(function(element) {
            element.observe('click', function(event) {
                this._buildDetails();
                }.bind(this));
        }.bind(this));

        //listen for folder actions
        $$('.accordion_toggle').each(function(element){
            var activeT = this.activeTags;
            element.observe('click', function(event){
                if(event.target.className =='accordion_toggle rounded_border collapse' || event.target.className =='accordion_toggle rounded_border expand'){
                    new Effect.toggle(event.target.next(1),'Blind', {duration:.5, afterFinish: function(){doc.resizeDetails();}});
                    var id = event.target.getAttribute('tag_id');
                    if(event.target.className =='accordion_toggle rounded_border collapse'){
                        event.target.removeClassName('collapse');
                        event.target.addClassName('expand');
                        activeT.set(id, 'closed');
                    } else {
                        event.target.removeClassName('expand');
                        event.target.addClassName('collapse');
                        activeT.set(id, 'open');
                    }
                }
            }.bind(this));
            element.observe('mouseenter', function(event){
                event.target.down(0).setStyle({display:'inline'});
                event.target.down(0).next(0).setStyle({display:'inline'});
            });

            element.observe('mouseleave', function(event){
                event.target.down(0).setStyle({display:'none'});
                event.target.down(0).next(0).setStyle({display:'none'});
            });

            this.activeTags = activeT;
        }.bind(this));

        //listen for delete-icon actions
        $$('.remove_folder_icon').each(function(element){
            element.observe('click', function(event){
                this.destroyFolder(event);
            }.bind(this));
            element.observe('mouseenter', function(event){
                event.target.writeAttribute("src", "../../images/organizer/remove-icon-15x15.png" );
            });
            element.observe('mouseleave', function(event){
                event.target.writeAttribute("src", "../../images/organizer/remove-icon-bw-15x15.png" );
            });

        }.bind(this));

        $$('.edit_folder_icon').each(function(element){
            element.observe('click', function(event){
                this.renameFolder(event);
            }.bind(this));
            element.observe('mouseenter', function(event){
                event.target.writeAttribute("src", "../../images/organizer/edit-icon-15x15.png" );
            });
            element.observe('mouseleave', function(event){
                event.target.writeAttribute("src", "../../images/organizer/edit-icon-bw-15x15.png" );
            });
        }.bind(this));

        //listen for doc folder change
        document.observe("document:moved", function() {
           // this._buildFolders();
           // this._buildDocs();
            new Ajax.Request('/tags/get_tags_json', {
               onSuccess: function(transport) {
                   console.log('render');
                   $('tags_json').update(transport.responseText);
                   this.prepareData();
                   this.render();
               }.bind(this)
            });
        }.bind(this));

        document.observe('click', function(event){
            if((event.target.hasClassName('wrapper')||event.target.hasClassName('contents')) && this.activeItemId!=''){
                var elem = $('documents').select('[doc_id="'+this.activeItemId+'"]')[0];
                console.log(elem);
                elem.down(2).setStyle({display:'none'});
                this.activeItemId = '';
                elem.removeClassName('active');
                elem.addClassName('inactive');
                event.stop();
                this.resizeDetails();
            }
        }.bind(this));
    }

});

/* global objects */
document.observe('dom:loaded', function() {
    doc = new cDoc;
    doc.onChange();

    /* fire app:loaded */
    document.fire('app:loaded');
});