/* class declarations */

var cDoc = Class.create({

    classSelector: null,

    /* parsed tag info */
    tags: null,
    recent: null,
    docs: null,
    html: null,
    theDate: null,
    activeTags: null,
    activeItemId: '',
    h: null,
    typingTimer: setTimeout('', 100),                //timer identifier
    doneTypingInterval: 1000,  //time in ms, 2 second for example

    initialize: function() {
    	console.log("Initialize");
        this.prepareData();
        window.onresize = AppUtilities.resizeContents;
        AppUtilities.resizeContents();

        /* load class selecter widget - must be done here also in case nothing is selected */
        this.classSelector = new cClassSelector(true);
        //new Dialog.Box('rename_folder_modal');
        //$('rename_folder_modal').show();

        if(document.getElementById('userfield')!=null){
            $('userfield').observe('keydown', function(){
                clearTimeout(this.typingTimer);
                $('submit').setStyle({'display': 'none'});
                $('taken').setStyle({'display': 'none'});
                $('available').setStyle({'display': 'none'});
                $('validate').setStyle({'display':'none'});
            }.bind(this));

            $('userfield').observe('keyup', function(){
                if($('userfield').value.length != 0){
                    console.log("interval "+this.doneTypingInterval);
                    this.typingTimer = setTimeout(function(){this.checkUsername($('userfield').value);}.bind(this), this.doneTypingInterval);
                }
            }.bind(this));

            $('submit').observe('click', function(){
                if($('userfield').value.length != 0){
                    this.setUsername($('userfield').value);
                }
            }.bind(this));
        }
    },

    prepareData: function() {
    	console.log("prep");
    	/* organize and set json member */
        this.tags = [];
        $('tags_json').innerHTML.evalJSON().collect(function(tag) {
            this.tags.push([tag['tag']['id'], tag['tag']]);
        }.bind(this));

        this.recent = [];
        console.log($('recent_json'));
        
        $('recent_json').innerHTML.evalJSON().collect(function(doc) {
//        	console.log(doc);
            this.recent.push(doc['document']);
        }.bind(this));

        //set all documents
        this.docs = new Hash();
        this.tags.each(function(tag){
//            console.log("Tag:");
//            console.log(tag[1]);
            tag[1]['documents'].each(function(doc){
//                console.log("Doc:");
//                console.log(doc);
//                console.log(doc['id']);
                this.docs.set(doc['id'], doc);
            }.bind(this));
        }.bind(this));


        if(this.activeTags==null){
            this.activeTags = new Hash();
            var activeT = this.activeTags;
            this.tags.each(function(tag){
                activeT.set(tag[1]['id'], 'closed');
            });
        }
        /* resize listener */
        AppUtilities.resizeContents();
    },

    onChange: function(){
        console.log('THIS DOT DOCS');
        var isEmpty = true;
        this.docs.each(function(d){
            isEmpty = false;
        });
        if(isEmpty) {
            this.render();
            $('documents').update("<div style='text-align: center; color:#d22b21; margin-top:150px;'>\
                                    <h1>Looks like you don't have any StudyEggs right now.</h1>\
                                    <h2 style='color:#595448; margin-top:15px;'>Check out the <a href='/store'>EggStore</a> and snag yourself some knowledge!</h2>");
            $('left_container').setStyle({"display":"none"});
            $('documents').setStyle({"width":"100%"});
        } else {
            $('left_container').setStyle({"display":"block"});
            $('documents').setStyle({"width":"70%"});
            this.render();
        }
    },

    _buildFolders: function(){
        var html = '';
        html += '<div class="accordion_toggle rounded_border collapse" tag_id="recent" >Recent Documents</div><div style="clear:both;"></div>\
              <div id="accordion_content_recent" class="accordion_content" tag_id="recent" style="display:block;"></div>';
        this.tags.each(function(tag) {
          var icon = 'collapse';
          var style='style="display:block;"';
          if(this.activeTags.get(tag[1]['id'])=='closed'){
              icon = 'expand';
              style = 'style= "display:none;"';
          }
          html += '<div class="accordion_toggle rounded_border '+icon+'" tag_id="'+tag[1]['id']+'">'+tag[1]['name']+'\
              </div><div style="clear:both;"></div>\
              <div id="accordion_content_'+tag[1]['id']+'" class="accordion_content" tag_id="'+tag[1]['id']+'" '+style+'></div>';
        }.bind(this));
        $('documents').update(html);

    },

    _buildDocs: function(){
        console.log("BUILDDOCS aiID: "+this.activeItemId);
        var html = '';
        //Build Recent Documents
        console.log(this.recent);
        this.recent.each(function(doc){
            var tName = "unknown";
            this.tags.each(function(t){
               if(t[0]==doc['tag_id']){
                   tName = t[1]['name'];
               }
            }.bind(this));
            //if($(this.activeItemId)){
            if((doc['id']+'_recent')==this.activeItemId){
                  html+= '<div class="doc_item active" doc_id="'+doc['id']+'" id="'+doc['id']+'_recent">\
                    <!--<input type="checkbox" class="chbox" doc_id="'+doc['id']+'"/>-->\
                    <span class="doc_title" doc_id="'+doc['id']+'">'+doc['name']+' </span> ('+tName+')\
                    <div class="doc_actions">\
                    <!--<span class="remove_doc" doc_id="'+doc['id']+'"><img class="doc_action_img" doc_id="'+doc['id']+'" src="../../images/organizer/remove-icon-15x15.png"></span>-->\
                    </div>\
                    </div>';
              //}
                } else {
                  html += '<div class="doc_item inactive" doc_id="'+doc['id']+'" id="'+doc['id']+'_recent">\
                    <!--<input type="checkbox" class="chbox" doc_id="'+doc['id']+'"/>-->\
                    <span class="doc_title" doc_id="'+doc['id']+'">'+doc['name']+' </span> ('+tName+')\
                    <div class="doc_actions">\
                    <!--<span class="remove_doc" doc_id="'+doc['id']+'"><img class="doc_action_img" doc_id="'+doc['id']+'" src="../../images/organizer/remove-icon-15x15.png"></span>-->\
                    </div>\
                    </div>';
              }
        }.bind(this));
        $('accordion_content_recent').update(html);

        //Builds All Documents
        html = ''
        this.tags.each(function(tag) {
          console.log(tag[1]);
          console.log(tag[1].id);
          tag[1]['documents'].each(function(doc){
              //this.docs.set(doc['id'], doc);
              ///if($(this.activeItemId)){
              if(doc['id']==this.activeItemId){
                  html+= '<div id="'+doc['id']+'" class="doc_item active" doc_id="'+doc['id']+'">\
                    <!--<input type="checkbox" class="chbox" doc_id="'+doc['id']+'"/>-->\
                    <span class="doc_title" doc_id="'+doc['id']+'">'+doc['name']+'</span>\
                    <div class="doc_actions">\
                    <!--<span class="remove_doc" doc_id="'+doc['id']+'"><img class="doc_action_img" doc_id="'+doc['id']+'" src="../../images/organizer/remove-icon-15x15.png"></span>-->\
                    </div>\
                    </div>';
              //}
                } else {
              html += '<div id="'+doc['id']+'" class="doc_item inactive" doc_id="'+doc['id']+'">\
                    <!--<input type="checkbox" class="chbox" doc_id="'+doc['id']+'"/>-->\
                    <span class="doc_title" doc_id="'+doc['id']+'">'+doc['name']+'</span>\
                    <div class="doc_actions">\
                    <!--<span class="remove_doc" doc_id="'+doc['id']+'"><img class="doc_action_img" doc_id="'+doc['id']+'" src="../../images/organizer/remove-icon-15x15.png"></span>-->\
                    </div>\
                    </div>';
              }
          }.bind(this));

          var elemId = 'accordion_content_'+tag[1]['id'];
          $(elemId).update(html);
          html='';
        }.bind(this));
    },

    _buildDetails: function(){
        /*console.log("BUILDDEETS aiID: "+this.activeItemId);
        var html = '';
        var checkedList = [];
        $$('.chbox').each(function(ele){
           if( $(ele).checked )
           {
               checkedList.push($(ele).getAttribute('doc_id'));
           }
        });
        if(checkedList[0] == null && this.activeItemId==''){
            html += "<h2 style='color:#595448; margin-top:15px text-align:center;'>Check out the <a href='/store'>EggStore</a> for more!</h2>";
        } else if((checkedList[0] == null && this.activeItemId!='')||(checkedList[1] == null && this.activeItemId!='')){
            var singleDoc = this.docs.get($(this.activeItemId).readAttribute('doc_id'));
            var d = singleDoc['created_at'].split('-');
            console.log(singleDoc);
            this.convertDate(new Date(d[0], d[1], d[2].substring(0,2)));
            var created = this.theDate;
            d = singleDoc['updated_at'].split('-');
            this.convertDate(new Date(d[0], d[1], d[2].substring(0,2)));
            var updated = this.theDate;
            var selector ='<select id="tag_id" class="selector">';
            this.tags.each(function(t){
                var s = ''
                if(t[0]==singleDoc['tag_id']) {s = 'selected = "selected"';}
                selector +='<option value="'+t[0]+'" '+s+'>'+t[1]['name']+'</option>';
            });
            selector += '</select>';
            
            html += '<div id="metainfo" doc_id="'+$(this.activeItemId).readAttribute('doc_id')+'">\
                    '+selector+'<img alt="loading" id="doc_loading" src="../../images/shared/fb-loader.gif" style="margin-left:7px;visibility:hidden;">\
                    <img class="elbow" src="../../images/organizer/elbow-icon.png"/><div id="sdt" class="single_doc_title"><span id="detail_name">'+singleDoc['name']+'</span></div>\
                    <div style="clear: both;"></div><h4 class="details_label">Created On: </h4>\
                    <em>'+created+'</em><br/>\
                    <h4 class="details_label">Last Updated: </h4>\
                    <em>'+updated+'</em></div>';
//                    <h4 class="details_label">Push Review: </h4>\
//                    <em>'+updated+'</em></div>';
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
           $('create_folder').stopObserving();
           $('create_folder').observe('click', function(event){
               $('new_folder_menu').show();
            }.bind(this)); 
        }

        this.resizeDetails();*/

        /* load class selecter widget */
        /*
        this.classSelector = new cClassSelector(true);

        //listener for doc name change
        $$('.single_doc_title').each(function(elem){
            elem.observe('click', function(event) {
                event.target.stopObserving();
                var title = $('sdt').down(0).innerHTML;
                $('sdt').innerHTML = '<input id="edt" class="edit_doc_title" value="'+title+'" />';
                $('edt').focus();
                $('edt').select();
                $$('.edit_doc_title').each(function(elem){
                    elem.observe('keypress', function(e) {
                        if (e.keyCode == 13) e.target.blur();
                    }.bind(this));

                    elem.observe('blur', function(){
                        console.log('blur start');
                        var newTitle = $('edt').value;
                         $('sdt').innerHTML = '<span id="detail_name" >'+newTitle +'</span>';
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
                                   onComplete: function(transport) {
                                       console.log('tags json success1');
                                       $('tags_json').update(transport.responseText);
                                       console.log('tags json success2');
                                   }.bind(this)
                                });
                                console.log('tags json POST');
                                new Ajax.Request('/tags/get_recent_json', {
                                   onSuccess: function(transport) {
                                       console.log('recent json success1');
                                       $('recent_json').update(transport.responseText);
                                       console.log('recent json success2');
                                       //this.prepareData();
                                       //this.render();
                                       //this._buildDetails();
                                   }.bind(this),
                                   onComplete: function(){
                                       console.log('recent json complete');
                                       this.prepareData();
                                       console.log('recent json complete1');
                                       this.render();
                                       console.log('recent json complete2');
                                   }.bind(this)
                                });
                            }.bind(this)
                        });
                        } else {this._buildDetails();}
                    }.bind(this));
                }.bind(this));
            }.bind(this));
        }.bind(this));*/
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

        this.theDate = (m_names[curr_month - 1] +" "+ curr_date + "<sup>" + sup + "</sup> " + " " + curr_year);
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
                new Ajax.Request('/tags/get_recent_json', {
                   onSuccess: function(transport) {
                       $('recent_json').update(transport.responseText);
                   }.bind(this),

                   onComplete: function(){
                       this.activeItemId = '';
                    this.prepareData();
                    this.render();
                   }.bind(this)
                });
            }.bind(this),
            onFailure: function(transport) {
                alert('There was an error removing the document.');
            }
        });
    },

    reviewDocument: function(docId){
        /* new document */
        self.document.location.href = '/review/' + docId
    },

    destroyFolder: function(event){
        new Dialog.Box('delete_folder_modal');
        $('delete_folder_modal').show();
        $('submit_delete').observe('click', function(){
            /* request */
            $('submit_delete').stopObserving();
            var tagId = event.target.getAttribute('id');
            tagId = tagId.substring(7);
            console.log(tagId);
            new Ajax.Request('/tags/' + tagId, {
                method: 'delete',
                onSuccess: function() {
                    console.log('SUCCESS');
                    new Ajax.Request('/tags/get_tags_json', {
                       onSuccess: function(transport) {
                           console.log('tags json success');
                           $('tags_json').update(transport.responseText);
                       }.bind(this)
                    });
                    new Ajax.Request('/tags/get_recent_json', {
                       onSuccess: function(transport) {
                           console.log('recent json success');
                           $('recent_json').update(transport.responseText);
                       }.bind(this),
                       onComplete: function(){
                           console.log('prep data')
                           this.prepareData();
                           console.log('render')
                           this.render();
                       }.bind(this)
                    });
                }.bind(this),
                onFailure: function(transport) {
                    alert('There was an error removing the directory. Please try again');
                    console.log('Failure: ' + transport.responseText);
                }
            });
            $('delete_folder_modal').hide();
            console.log('hidemodal');
        }.bind(this));
        $('submit_cancel').observe('click', function(){
            $('delete_folder_modal').hide();
        });
    },

    renameFolder: function(event){
         console.log('Rename Folder Start');
        /* request params */
        new Dialog.Box('rename_folder_modal');
        $('update_icon').writeAttribute({"href":"/choose_icon/"+event.target.getAttribute('id').substring(5)});
        console.log('update icon!');
        $('rename_folder_modal').show();

        $('submit_rename').observe('click', function(){
        var tagName = $('rename_field').value;
        $('rename_folder_modal').hide();
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
                alert('There was an error renaming the StudyEgg. Please try again');
            },
            onSuccess: function() {
                console.log('SUCCESS');
                new Ajax.Request('/tags/get_tags_json', {
                   onSuccess: function(transport) {
                       console.log('tags json success');
                       $('tags_json').update(transport.responseText);
                   }.bind(this)
                });
                new Ajax.Request('/tags/get_recent_json', {
                   onSuccess: function(transport) {
                       console.log('recent json success');
                       $('recent_json').innerHTML = transport.responseText;
                       console.log('set innerhtml');
                       this.prepareData();
                       this.render();
                       console.log('Rename Folder End');
                   }.bind(this)
                });
            }.bind(this)
        });
        }.bind(this));
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
                $('username').id = "username_chosen";
               } else {
                   alert('there was an error with your screen name');
               }
           }
        });
    },

    render: function(){
    	console.log("Render");
    	this._buildFolders();
        this._buildDocs();
        this._buildDetails();
        this.resizeDetails();
        //Add Listeners
        //
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
           
            this.activeTags = activeT;
        }.bind(this));

        //listen for doc folder change
        document.observe("document:moved", function() {
            new Ajax.Request('/tags/get_tags_json', {
               onSuccess : function(transport) {
                   $('tags_json').update(transport.responseText);
               }.bind(this),
               onComplete: function(){
                   this.prepareData();
                   this.render();
               }.bind(this)
            });
            new Ajax.Request('/tags/get_recent_json', {
               onSuccess: function(transport) {
                   $('recent_json').update(transport.responseText);
               }.bind(this),
               onComplete: function(){
                   this.prepareData();
//                   this.render();
                   this._buildFolders();
                   this._buildDocs();
               }.bind(this)
            });
        }.bind(this));

        document.observe("document:new_folder_created", function() {
            new Ajax.Request('/tags/get_tags_json', {
               onSuccess: function(transport) {
                   $('tags_json').update(transport.responseText);
               }.bind(this)
            });
            new Ajax.Request('/tags/get_recent_json', {
               onSuccess: function(transport) {
                   $('recent_json').update(transport.responseText);
               }.bind(this),
               onComplete: function(){
                   this.prepareData();
                   this.render();
               }.bind(this)
            });
        }.bind(this));

        document.observe('click', function(event){
            if((event.target.hasClassName('wrapper')||event.target.hasClassName('contents') ||
                event.target.readAttribute('id')=='documents') && this.activeItemId!=''){
                var elem = $(this.activeItemId);
                console.log(elem);
                elem.down(2).setStyle({display:'none'});
                this.activeItemId = '';
                elem.removeClassName('active');
                elem.addClassName('inactive');
                event.stop();
                this._buildDetails();
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

document.observe('lightview:loaded', function() {
    new Ajax.Request('/users/has_username', {
                   onSuccess: function(transport) {
                       console.log(transport.responseText);
                       if(transport.responseText == "false"){
                             Lightview.show({
                                href: 'username',
                                rel: 'inline',
                                options: {
                                  width: 400,
                                  height: 220,
                                  overlayClose: false,
                                  closeButton: false
                                }
                              });
                              pageTracker._trackPageview("/homepage/new_user");
                       } else {pageTracker._trackPageview("/homepage/old_user");}
                   }.bind(this)
                });
});