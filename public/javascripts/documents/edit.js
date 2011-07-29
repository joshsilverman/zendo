/* class declarations */

var cDoc = Class.create({

    outline: null,
    rightRail: null,
    editor: null,
    tipTour:null,
    iDoc: null,
    utilities: null,

    readOnly:null,
    newDoc: null,
    docCount: null,
    toggler: null,

    initialize: function() {

        /* set new document attr */
        this.newDoc = $('new_doc').innerHTML == "true";
        this.docCount = $('doc_count').innerHTML;
        this.readOnly = $('read_only').innerHTML == 'true'
        if (this.newDoc) {
            /* set attr and remove node (in case there are edits followed by reload) */
            $('new_doc').innerHTML = "false";
        }
        else this.newDoc = false;

        /* check for reload cookie */
        var reload = AppUtilities.Cookies.read('reloadEditor') == 'true';
        if (reload) {
            AppUtilities.Cookies.create('reloadEditor', 'false', 3);
            self.document.location.reload(true);
            return;
        }

        /* select all in doc name on click */
        $('document_name').observe('click', function(e) {e.target.select();});

        /* utilities */
        this.utilities = new cUtilities();

        /* load class selecter widget */
        new cClassSelector();

        /* disable feedback */
        if (document.viewport.getWidth() < 1000) {
            AppUtilities.vendorScripts.unset("script_userecho")
        }

        /* set listeners for helper panel*/
        $('helper_panel_contents').show();
        this.toggler = false;
        $('helper_panel_tab').observe('click', function(){
            if(this.toggler){
                new Effect.Move($('helper_panel_container'), {
                  x: 214, y: 0, mode: 'relative',
                  transition: Effect.Transitions.spring
                });
                $('helper_panel_tab').removeClassName('in');
                $('helper_panel_tab').addClassName('out');
                this.toggler = false;
            } else {
                new Effect.Move($('helper_panel_container'), {
                  x: -214, y: 0, mode: 'relative',
                  transition: Effect.Transitions.spring
                });
                $('helper_panel_tab').removeClassName('out');
                $('helper_panel_tab').addClassName('in');
                this.toggler = true;
            }
        }.bind(this));

    },

    onEditorLoaded: function() {

        try {
            var iframe = $('editor_ifr');
            this.iDoc = iframe.contentWindow || iframe.contentDocument;
        }
        catch(e) {
            doc.onEditorLoaded.bind(this).delay(.05);
            return;
        }

        /* load outline/right rail objs */
        this.iDoc = this.iDoc.document;
        this.outline = new cOutline(this.iDoc);
        this.rightRail = new cRightRail();
        this.rightRail.build.bind(this.rightRail).defer();
        this.editor = tinyMCE.getInstanceById("editor");

        /* click observers */
        Event.observe($("save_button"),"click",function(e){doc.outline.autosave(e);});
        Event.observe($("review_button"),"click",function(e){
            AppUtilities.Cookies.create('reloadEditor', 'true', 3);
            window.location = "/review/" + doc.outline.documentId;            
            
        }.bind(this));

		/* observe push enable */
        Event.observe($("mobile_review"), "click", function(e) {
        	var requestUrl = "/documents/enable_mobile/" + doc.outline.documentId + "/" + (($("mobile_review").checked)?1:0);
        	//TODO fill callback parameters
            new Ajax.Request(requestUrl, {});
        }.bind(this));

        $("doc_options").removeClassName("loading");
        $('editor_parent').show();
        this.onResize();
        this.tipTour = new cTipTour();

        /* resize listener */
        window.onresize = this.onResize;
        try {$("document_name").focus();}
        catch (e) {}

        /* make shareable */
        this.makeShareable();

        /* display quick tips of no cards */
        if (doc.outline.lineIds.size() > 0) {
            new Effect.Move($('helper_panel_container'), {
              x: -214, y: 0, mode: 'relative'
            });
            $('helper_panel_tab').removeClassName('out');
            $('helper_panel_tab').addClassName('in');
            this.toggler = true;
        }
    },

    onResize: function() {

        /* set to visible */
        var editorContainer = $('editor_container');
        var rightRail = $('right_rail');
        var helperContainer = $('helper_panel_container');
        var cardContainer = $('card_container');
        
        editorContainer.show();
        rightRail.show();
        helperContainer.show();
        cardContainer.show();

        /* calculations */
        var bottomMargin = 50;
        var editorVerticalSpaceHeight = document.viewport.getDimensions()['height']
            - editorContainer.cumulativeOffset().top - bottomMargin;
        var editorWhitespace = $('editor_tbl');

        /* set minimums */
        if (editorVerticalSpaceHeight < 200) editorVerticalSpaceHeight = 200;

        /* set heights */
        var editorIfrHeight = editorVerticalSpaceHeight - 20;
        var rightRailHeight = editorVerticalSpaceHeight - 20;// + 20;
        if (doc.readOnly) {
            editorIfrHeight += 28;
            rightRailHeight += 28;
            rightRail.setStyle({marginTop: '0px'});
            helperContainer.hide();
        }
//        editorWhitespace.setStyle({height: editorIfrHeight + 10 + 'px'});
        rightRail.setStyle({height: rightRailHeight - 20 + 'px'});
        helperContainer.setStyle({height: rightRailHeight - 20+ 'px'});
        cardContainer.setStyle({height: rightRailHeight - 30 + 'px'});
        $("editor_ifr").setStyle({height: editorIfrHeight - 20 + 'px'});
        

        /* set widths */
        var editorWidth = 660;
        $("editor_tbl").setStyle({width: editorWidth + 'px'});
        $("editor_parent").setStyle({width: editorWidth + 'px'});
    },

    share: function() {
    	console.log("About to req");
        new Ajax.Request('/documents/share', {
            method: 'put',
            //console.log($("share_email_input").value);
            //console.log(doc.outline.documentId);
            parameters: {id : doc.outline.documentId, email: $("share_email_input").value},
            onSuccess: function(transport) {
            	console.log("success");
                var token = '<span class="token removable" viewer_id="' +
                    transport.responseText +
                    '">' +
                    $("share_email_input").value +
                    '<span class="remove" >X</span></span>'
                $("viewers").insert({"bottom": token});
            },
            onCreate: function() {
            	console.log("create");
                $("update_share_loading").setStyle({'visibility': 'visible'});
            },
            onComplete: function() {
                $("share_email_input").value = "";
                $('update_share_loading').setStyle({'visibility': 'hidden'});
            }
        });
    },

    unshare: function(token) {
        new Ajax.Request('/documents/unshare', {
            method: 'put',
            parameters: {id:doc.outline.documentId, viewer_id: token.readAttribute("viewer_id")},
            onSuccess: function() {token.remove();}
        });
    },

    makeShareable: function() {
        new Dialog.Box('share_menu');
        if ($('share_button')) $("share_button").observe("click",$('share_menu').show);
        if ($('document_public')) $('document_public').observe('change', function() {doc.updatePrivacy();});

        document.observe("click", function(e) {
            var token = e.target.up('.token');
            if (e.target.hasClassName("remove")) doc.unshare(token);
        });

        new Ajax.Autocompleter("share_email_input", "share_email_choices", "/users/autocomplete", {
            afterUpdateElement: doc.share
        });
    },

    updatePrivacy: function() {
        new Ajax.Request('/documents/update_privacy', {
            method: 'post',
            parameters: {id: this.outline.documentId, bool: $('document_public').value},
            onCreate: function() {
                if ($('document_public')) $('document_public').disabled = true;
                $("update_privacy_loading").setStyle({'visibility': 'visible'});
            },
            onComplete: function() {
                if ($('document_public')) $('document_public').disabled = false;
                $('update_privacy_loading').setStyle({'visibility': 'hidden'});
            }
        });
    }
});

var cOutline = Class.create({
    iDoc: null,
    documentId: null,

    autosaver: null,

    unsavedChanges: [],
    savingChanges: [],
    deleteNodes: [],
    deletingNodes: [],
    newNodes: false,
    lineIds: null,

    saving: false,
    nextSaveTimer: null,

    initialize: function(iDoc) {
        this.iDoc = iDoc;
        this.documentId = $('doc_id').innerHTML;
        this.lineIds = $H($('line_ids').innerHTML.evalJSON());
        
        this.autosaver = new PeriodicalExecuter(this.autosave.bind(this), 4);

        $("document_name").observe('keypress', function(e) {
            if (e.keyCode == 13) doc.editor.focus();
            doc.editor.isNotDirty = false;
            this.onChange(null);
        }.bind(this));
    },

    updateIds: function() {

        /* don't run if no lineids */
        if (!this.lineIds) return;

        /* iterate through id, line_id hash */
        this.lineIds.each(function(idArray) {

            /* add id */
            if (this.iDoc.getElementById(idArray[1])) {
                this.iDoc.getElementById(idArray[1]).setAttribute('line_id', idArray[0]);

                /* delete if in hash but not active */
                if (!Element.hasClassName(this.iDoc.getElementById(idArray[1]), "active")) {
                    this.deleteNodes.push(idArray[0]);
                }
            }

            /* remove line if no node has the associated node id */
            else {
                this.deleteNodes.push(idArray[0]);
            }
        }.bind(this));

        /* iterate through nodes, make sure line_id is in hash */
        Element.select(doc.outline.iDoc, '.outline_node').each(function(node) {

            /* parent attribute setter */
            doc.outline.iDoc.body.setAttribute("id","node_0"); // @todo can be placed in outline initialization if this strat remains
            var parent = (node.parentNode.tagName != "UL" && node.parentNode.tagName != "OL")
                ? node.parentNode
                : node.parentNode.parentNode;

            //set parent - if changed, treat node as new
            if (   node.getAttribute("parent")
                && node.getAttribute("parent") != parent.id) {

                this.deleteNodes.push(node.getAttribute("line_id"));
                node.setAttribute("line_id", '');
                node.setAttribute("id", '');
            }
            node.setAttribute("parent", parent.id);

            /* treat nodes that aren't in returned hash as new - set doc as changed */
            if (   this.lineIds.get(node.getAttribute('line_id'))
                != node.id) {

                node.setAttribute('line_id', '');
                this.unsavedChanges.push(node.id);
            }

            /* assure all changed nodes in unsavedChanges - shouldn't be necessary */
            if (   node.getAttribute('changed') == '1'
                && this.unsavedChanges.indexOf(node.id) == -1) {

                this.unsavedChanges.push(node.id);
            }

            /* new nodes */
            if (!node.getAttribute('line_id')) this.newNodes = true;
        }.bind(this));
    },

    autosave: function() {

        /* don't defer save if already saving */
        if (this.saving) {
            window.clearTimeout(this.nextSaveTimer);
            this.nextSaveTimer = doc.outline.autosave.bind(this).delay(2);
            return;
        }

        if (doc.readOnly) return;

        if(doc.editor.isDirty() || !doc.editor.isNotDirty) {
            doc.editor.isNotDirty = true;

            doc.outline.updateIds();
            doc.rightRail.sync();
            var saveButton = $('save_button');
            saveButton.disabled = true;
            saveButton.innerHTML = 'Saving';
            saveButton.addClassName("saving");
            var d = new Date();
            var today = d.getFullYear()+'-'+(d.getMonth()+1)+'-'+ d.getDate();
            /* save */
            console.log("yooooooo");
            new Ajax.Request('/documents/'+this.documentId, {
                method: 'put',
                parameters: {'html': doc.editor.getContent(),
                             'name': $('document_name').value,
                             'delete_nodes': this.deleteNodes.toString(),
                             'edited_at': today},

                onCreate: function() {

                    this.saving = true;

                    /* track saving changes */
                    this.unsavedChanges = this.unsavedChanges.uniq();
                    this.unsavedChanges.each(function(domId) {
                        if (domId && this.iDoc.getElementById(domId)) {
                            Element.writeAttribute(this.iDoc.getElementById(domId), {'changed': '0'});
                            Element.removeClassName(this.iDoc.getElementById(domId), 'changed');
                        }
                    }.bind(this));
                    this.savingChanges = this.unsavedChanges;
                    this.unsavedChanges = [];

                    /* track nodes being delete, clear nodes to be deleted */
                    this.deletingNodes = this.deleteNodes;
                    this.deleteNodes = [];

                }.bind(this),

                onSuccess: function(transport) {
                    this.lineIds = $H(transport.responseText.evalJSON());
                    this.updateIds();

                    /* set new nodes to false */
                    this.newNodes = false;

                    /* save button styling */
                    saveButton.disabled = false;
                    saveButton.innerHTML = 'Saved';

                    /* cancel navigate away while saving warning */
                    window.onbeforeunload = null;
                }.bind(this),

                onFailure: function(transport) {
					console.log("Failed!");
                    /* add unsuccessfully saved changes back to unsaved changes and set attributes */
                    this.unsavedChanges = this.unsavedChanges.concat(this.savingChanges).uniq();
                    this.unsavedChanges.each(function(domId) {
                        if (this.iDoc.getElementById(domId)) {
                            Element.writeAttribute(this.iDoc.getElementById(domId), {'changed': '1'});
                            Element.addClassName(this.iDoc.getElementById(domId), 'changed');
                        }
                    }.bind(this));

                    /* add unsuccessfully deleted back to deleteNodes */
                    this.deleteNodes = this.deleteNodes.concat(this.deletingNodes);

                    /* save button styling */
                    saveButton.disabled = false;
                    saveButton.innerHTML = 'Save';
                    this.autosave();

                    /* signed out */
                    if (transport.status == 401) {
                        alert("Please sign in again.");
//                        Lightview.show({
//                            href: '/doc.editor.isNotDirty = false;users/simple_sign_in',
//                            rel: 'ajax',
//                            options: {
//                                autosize: true,
//                                topclose: true,
//                                ajax: {
//                                    method: 'get',
//                                    evalScripts: true,
//                                    onComplete: function(){
//                                        console.log("loaded");
//                                        console.log($('user_email'));
//                                        $('user_email').focus();}
//                                }
//                            }
//                        });
                    }
                    else {
                        alert("There was an error saving your document. Please try saving again.");
                    }

                }.bind(this),

                onComplete: function() {

                    /* clear saving changes */
                    this.savingChanges = []
                    this.deletingNodes = []

                    this.saving = false;
                }.bind(this)
            });
        }
    },

    onChange: function(target, e) {
        if (e && e.keyCode >= 37 && e.keyCode <= 40) return;

        if (target) {
            if (target.tagName != "P" && target.tagName != "LI" && target.tagName != "DIV")  {
                target = Element.up(target, "p, li, div");
                if (!target) {
                    return;
                }
            }

            Element.addClassName(target, 'changed');
            Element.writeAttribute(target, 'changed', "1");

            /* new/existing card handling */
            var id = Element.readAttribute(target, 'id') || null;
            if (!id) {
                doc.rightRail.createCard(target);
            }
            else if (doc.iDoc.getElementById(id) != target) {
                target.id = "";
                Element.removeClassName(target, "active");
                doc.rightRail.createCard(target);
            }
            else if(doc.rightRail.cards.get(id)) {
                doc.rightRail.updateFocusCardWrapper(id, target);
            }
        }

        if (doc.editor) {
            doc.editor.isNotDirty = false;
            var saveButton = $('save_button');
            saveButton.disabled = false;
            saveButton.innerHTML = 'Save';
            saveButton.removeClassName("saving");
        }
    },

    activateNode: function(checkbox) {

        //vars
        var card = checkbox.up('.card');
        var domId = doc.utilities.toNodeId(card);
        var node = this.iDoc.getElementById(domId);

        //activate/dactivate card
        if (checkbox.checked) {
            node.setAttribute('active', true);
            Element.addClassName(node, 'active');
            doc.rightRail.cards.get(domId).activate();
        }
        else {
            node.setAttribute('active', false);
            Element.removeClassName(node, 'active');
            doc.rightRail.cards.get(domId).deactivate();
        }

        /* autosave */
        node.setAttribute('changed', '1');
        this.unsavedChanges.push(node.id);
        this.autosave();

        /* refocus on editor */
        doc.editor.focus();
    },

    onExeccommand: function(editor_id, elm, command, user_interface, value) {

        /* bold triggers card creation */
        if (command == "Bold") {
            var htmlMatch = doc.editor.selection.getContent({format : 'html'});
            var rawMatch = doc.editor.selection.getContent({format : 'raw'}).match(/^<strong>.*<\/strong>$/);
            if (htmlMatch && htmlMatch.length > 0) {
                Element.select(elm, "strong").each(function(element) {
                    if (element.innerHTML == htmlMatch.gsub(/<[^>]*>/, ''))
                        var card = doc.rightRail.createCard(element);
                });
            }
        }
    }
});

var cRightRail = Class.create({

    cardCount: 1,
    cards: new Hash(),
    inFocus: null,

    updateFocusCardTimer: null,

    build: function() {

        /* set card count */
        Element.select(doc.outline.iDoc, 'li, p, div, strong').each(function (node) {
            var index = parseInt(node.id.replace('node_', ''));
            if (index >= this.cardCount) this.cardCount = index + 1;
        }.bind(this));

        /* sync */
        this.sync();

        /* activate card */
        document.observe('click', function(event) {
           if(event.target.hasClassName('card_activation')) doc.outline.activateNode(event.target);
        }.bind(this));
    },

    /* wrapper function for focus/update to limit the number of calls! */
    updateFocusCardWrapper: function(id, target) {

        /* clear timer */
        window.clearTimeout(this.updateFocusCardTimer)

        /* make call */
//        this.updateFocusCardTimer =
//            (function () {
                if (doc.rightRail.cards.get(id)) {
                    doc.rightRail.cards.get(id).update(target, false);
                    doc.rightRail.focus(id);
                }
//            }).delay(.25)
    },

    createCard: function(node) {

        var cardNumber;

        //check node is valid
        if (   node.tagName.toUpperCase() != 'LI'
            && node.tagName.toUpperCase() != 'P'
            && node.tagName.toUpperCase() != 'STRONG'
            && node.tagName.toUpperCase() != 'DIV') return null;

        Element.addClassName(node, "outline_node");

//        /* filter styles */
//        var style = Element.readAttribute(node, 'style');
//        style = style.replace(/font[^;]+;/, "");
//        Element.writeAttribute(node, 'style', style);

        //clear cloned node info if not first node with given id
        if (!node.id) {
            cardNumber = this.cardCount++;
            Element.removeClassName(node, "active");
            Element.writeAttribute(node, 'active', false);
            Element.writeAttribute(node, 'line_id', '');
            node.id = "node_" + cardNumber;
            Element.addClassName(node, "changed");
        }

        else {
            if (doc.rightRail.cards.get(node.id)) return;
            cardNumber = parseInt(node.id.substr(5));
            if (isNaN(cardNumber)) {
                node.id = "";
                this.createCard(node);
                return;
            }
            if (cardNumber >= this.cardCount) {
                this.cardCount = cardNumber + 1;
            }
        }

        var card = new cCard(node, cardNumber);
        doc.rightRail.cards.set('node_' + cardNumber, card);

        return card;
    },

    focus: function(id) {

        //normalize id
        var cardId = doc.utilities.toCardId(id);

        //check card exists
        if (!$(cardId)) return;

        //scroll function
        var rightRail = document.getElementById("right_rail");
        var scrollTo = function () {
            rightRail.scrollTop = this.inFocus.offsetTop
                - this.inFocus.getHeight()
                - $('right_rail').getHeight()/2
                - 10;
        }.bind(this);

        //check if already in focus - if so, just make sure scrollTtop is still correct
        if(this.inFocus && this.inFocus.id == cardId) {
            scrollTo();
            return;
        }

        //unfocus previously focused
        else if(this.inFocus && this.inFocus.id != cardId) {
            Element.removeClassName(this.inFocus, 'card_focus');
            var domIdPrev = doc.utilities.toNodeId(this.inFocus);
            var nodePrev = doc.outline.iDoc.getElementById(domIdPrev);
            if (nodePrev && this.cards.get(domIdPrev)) this.cards.get(domIdPrev).update(nodePrev, true);
        }

        //focus
        this.inFocus = $(cardId);
        Element.addClassName(this.inFocus, 'card_focus');
        scrollTo();
    },

    /* render right rail - should not be called unless dones so explicitly by
     * user or the rail cards are no longer in sync with the  */
    sync: function() {

        /* collect all potential nodes - li/p with text */
        var nodes = Element.select(doc.outline.iDoc, 'li, p, div, strong')
            .findAll(function (node) {return node.innerHTML});

        /* try to create card - only will be created if doesn't exist */
        nodes.each(function(node) {this.createCard(node);}.bind(this));

        /* destroy cards if node no longer exists */
        this.cards.each(function(cardArray) {
            var domId = cardArray[0];
            var card = cardArray[1];
            var node = doc.outline.iDoc.getElementById(domId);
            if (!node) card.destroy();
        });
    }
});

var cCard = Class.create({

    cardNumber: null,

    front: '',
    back: '',
    text: '',

    active: false,
    elmntCard: null,
    domId: null,
    updating: false,

    autoActivate: false,
    autoActivated: false,    //if auto activated and later format becomes unnacceptable - autoDeactivate

    parser: null,

    initialize: function(node, cardCount) {

        /* set count */
        this.cardNumber = cardCount;

        /* set domId */
        this.domId = node.id;

        /* card in dom */
        var cardHtml = '<div id="card_' + this.cardNumber + '" class="rounded_border card"></div>';
        this._insert(cardHtml);
        this.elmntCard = $("card_" + this.cardNumber);

        /* set active - in case regenerating card for existing node */
        if (Element.hasClassName(node, 'active')) this.activate();

        /* update */
        this.update(node);
        if(doc.rightRail.cardCount==3 && doc.newDoc){
            new Effect.Move($('helper_panel_container'), {
                  x: -214, y: 0, mode: 'relative',
                  transition: Effect.Transitions.spring,
                  afterFinish: doc.tipTour.showReview()
                });
            $('helper_panel_tab').removeClassName('out');
            $('helper_panel_tab').addClassName('in');
            doc.toggler = true;
            //doc.tipTour.showReview();
        }
    },

    update: function(node, truncate) {
        //node exists?
        if (!node) {
            this.destroy();
            return;
        }

        this.active = Element.hasClassName(node, 'active');

        /* parse and render */
        this.text = node.innerHTML.split(/<[uoUO](?:l|L)/)[0];
        parser.parse(this);
        this.render(truncate);
    },

    activate: function() {
        this.active = true;
        $('card_' + this.cardNumber).addClassName('card_active');
        var node = doc.outline.iDoc.getElementById("node_" + this.cardNumber);
        Element.addClassName(node, "active");
        Element.removeClassName(node, "deactivated");
        doc.outline.onChange();
        this.render();
    },

    deactivate: function() {
        this.active = false;
        $('card_' + this.cardNumber).removeClassName('card_active');
        var node = doc.outline.iDoc.getElementById("node_" + this.cardNumber);
        Element.removeClassName(node, "active");
        Element.addClassName(node, "deactivated");
        var truncate = !this.inFocus || this.inFocus.id != 'card_' + this.cardNumber;
        doc.outline.onChange();
        this.render(truncate);
    },

    render: function(truncate) {

        var node = doc.outline.iDoc.getElementById('node_' + this.cardNumber);

        /* attempt autoactivate */
        if (this.autoActivate && !Element.hasClassName(node, "deactivated")) {
            this.autoActivated = true;
            this.autoActivate = false;
            this.activate();
            this.elmntCard.down('input').checked = 'yes';
            Element.addClassName(node, "active");
        }

        /* checkbox dom */
        var checkbox;
        if (this.active == true) checkbox = '<input type="checkbox" class="card_activation" checked="yes" />';
        else checkbox = '<input type="checkbox" class="card_activation" />';

        //is not active
        if (!this.active)
            this.elmntCard.innerHTML = checkbox + '<i>Click checkbox to activate</i>';

        //both sides set
        else if (this.back) {
            this.elmntCard.innerHTML = '<div class="card_front">'
                    + checkbox + '</div>\
                <div class="card_back">'+this.back+'</div>';
            this.elmntCard.down().insert(this.front);
        }

        //just front
        else if (this.elmntCard) {
            this.elmntCard.innerHTML = '<div class="card_front">'
                + checkbox + '</div>';
            this.elmntCard.down().insert(this.front);

            //autoDeactivate
            if (this.autoActivated) {
                this.autoActivated = false;
                this.deactivate();
                this.elmntCard.down('input').checked = '';
                var node = doc.outline.iDoc.getElementById('node_' + this.cardNumber);
                Element.removeClassName(node, "active");
            }
        }

        //no card to update
        else return;

    },

    destroy: function() {
        try {
            Element.remove(this.elmntCard);
            doc.rightRail.cards.unset('node_' + this.cardNumber);
        }
        catch (err) {}
    },

    _insert: function(cardHtml) {

        /* identify previous node in outline */

        //collect nodes which have cards
        var domId = 'node_' + this.cardNumber;
        var outlineNodes = Element.select(doc.outline.iDoc, '.outline_node');
        outlineNodes = $A(outlineNodes).findAll(function(node) {return node.id});

        //itererate backwards to find previous node; set id vars
        var outlineNodePrev, domIdPrev, cardIdPrev;
        for (var i = outlineNodes.length - 1; i >= 0; i--) {
            if (outlineNodes[i].id == domId && i != 0) {
                outlineNodePrev = outlineNodes[i-1];
                domIdPrev = outlineNodePrev.id;
                cardIdPrev = "card_" + domIdPrev.replace('node_', '');
                break;
            }
        }

        //insert first
        if (!cardIdPrev) {
            $('cards').insert({top: cardHtml});
        }

        //previous node but no previous card
        else if (cardIdPrev && !$(cardIdPrev)) {

            //temp
            $('cards').insert({bottom: cardHtml});
        }

        //insert later
        else {
            $(cardIdPrev).insert({after: cardHtml});
        }
    }
});

var cTipTour = Class.create({
    
    initialize: function() {
        if (doc.newDoc && doc.docCount < 4) this.showTitle();
        var firstFocus = true;
        $('document_name').observe('keypress', function(e){
            if(firstFocus && e.keyCode == 13 && doc.newDoc){
                new Effect.Shake($('helper_panel_container'), {duration: 1, distance: 6});
                Tips.hideAll();
                firstFocus = false;
            }

        });
    },

    showTitle: function() {
        var doc_name = $("document_name");
        if (doc_name.prototip) $('document_name').prototip.show();
        else {
            new Tip(doc_name, $("tip_title"), {
                title: 'Getting started',
                style: 'protogrey',
                stem: 'topLeft',
                closeButton:true,
                hook: {target: 'bottomRight', tip: 'topLeft'},
                offset: {x: -13, y: 2},
                hideOn: false,
                showOn:false
            });
        }
        Tips.hideAll();
        doc_name.prototip.show();
    },

    showReview: function() {
        var reviewButton = $("review_button");
        new Tip(reviewButton, $("tip_review"), {
            title: 'Almost done',
            style: 'protogrey',
            closeButton:true,
            hook: {target: 'bottomLeft', tip: 'topRight'},
            offset: {x: 7, y: 5},
            hideOn: false,
            showOn:false,
            stem: 'topRight'
        });
        Tips.hideAll();
        reviewButton.prototip.show();
        $$('.prototip').each(function(item){
            new Effect.Fade(item, {delay: 4, duration: 3});
        });
    }
});

var cUtilities = Class.create({

    toNodeId: function(mixed) {
        var id = this._getId(mixed);
        if (id || id == 0) return 'node_' + id;
    },

    toCardId: function(mixed) {
        var id = this._getId(mixed);
        if (id || id == 0) return 'card_' + id;
    },

    _getId: function(mixed) {

        var id;

        //node or card
        if (Object.isElement(mixed)) id = mixed.id.replace('node_', '').replace('card_', '');

        //id
        else if (Object.isNumber(mixed)) id = mixed;

        //domId or cardId
        else if (Object.isString(mixed)) var id = mixed.replace('node_', '').replace('card_', '');

        return id;
    }
});

/* global objects */
document.observe('dom:loaded', function() {
    parser = new cParser();
    doc = new cDoc();

    /* fire app:loaded */
    document.fire('app:loaded');
});
