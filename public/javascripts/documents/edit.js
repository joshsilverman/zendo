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
    },

    onResize: function() {

        /* set to visible */
        var editorContainer = $('editor_container');
        var rightRail = $('right_rail');
        editorContainer.show();
        rightRail.show();

        /* calculations */
        var bottomMargin = 50;
        var editorVerticalSpaceHeight = document.viewport.getDimensions()['height']
            - editorContainer.cumulativeOffset().top - bottomMargin;
        var editorWhitespace = $('editor_tbl');

        /* set minimums */
        if (editorVerticalSpaceHeight < 200) editorVerticalSpaceHeight = 200;

        /* set heights */
        var editorIfrHeight = editorVerticalSpaceHeight - 20;
        var rightRailHeight = editorVerticalSpaceHeight;// + 20;
        console.log("bo");
        if (doc.readOnly) {
            console.log("yo");
            editorIfrHeight += 28;
            rightRailHeight += 28;
            rightRail.setStyle({marginTop: '0px'});
        }
        editorWhitespace.setStyle({height: editorVerticalSpaceHeight + 10 + 'px'});
        rightRail.setStyle({height: rightRailHeight - 30 + 'px'});
        $("editor_ifr").setStyle({height: editorIfrHeight + 'px'});


        /* set widths */
        var editorWidth = 660;
        $("editor_tbl").setStyle({width: editorWidth + 'px'});
        $("editor_parent").setStyle({width: editorWidth + 'px'});
    },

    share: function() {
        new Dialog.Box('share_menu');
        console.log($('share_menu'));
        $('share_menu').show();
//        $('test123').hide();
//        var openMenu = false;
//        if ($("share_button").menu_open == 'true') {
//            $("share_button").menu_open = 'false';
//            $('doc_options').morph('height:24px;');
//            console.log('close it');
//        }
//        else {
//            $("share_button").menu_open = 'true';
//            openMenu = true;
//            $('doc_options').morph('height:150px;');
//            console.log('open it');
//        }
    },

    makeShareable: function() {
        if ($('share_button')) $("share_button").observe("click",doc.share.bind(this));
        if ($('document_public')) $('document_public').observe('change', function() {doc.updatePrivacy();});
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

    initialize: function(iDoc) {
        this.iDoc = iDoc;
        this.documentId = $('doc_id').innerHTML;
        this.lineIds = $H($('line_ids').innerHTML.evalJSON());
        
        this.autosaver = new PeriodicalExecuter(this.autosave.bind(this), 4);

        $("document_name").observe('keypress', function(e) {
            console.log('doc name listener');
            if (e.keyCode == 13) doc.editor.focus();
            doc.editor.isNotDirty = false;
            this.onChange(null);
        }.bind(this));
    },

    updateIds: function() {

        /* don't run if no lineids */
        if (!this.lineIds) {
            console.log('cannot update ids');
            return;
        }
        else console.log('update ids');

        /* iterate through id, line_id hash */
        this.lineIds.each(function(idArray) {

            /* add id */
            if (this.iDoc.getElementById(idArray[1])) {
                this.iDoc.getElementById(idArray[1]).setAttribute('line_id', idArray[0]);

                /* delete if in hash but not active */
                if (!Element.hasClassName(this.iDoc.getElementById(idArray[1]), "active")) {
                    this.deleteNodes.push(idArray[0]);
                    console.log('deleting as it is no longer active' + idArray[0]);
                }
            }

            /* remove line if no node has the associated node id */
            else {

                this.deleteNodes.push(idArray[0]);
                console.log('deleting ' + idArray[0]);
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

                console.log('reset line id and id');
                this.deleteNodes.push(node.getAttribute("line_id"));
                node.setAttribute("line_id", '');
                node.setAttribute("id", '');
            }
            node.setAttribute("parent", parent.id);

            /* treat nodes that aren't in returned hash as new - set doc as changed */
            if (   this.lineIds.get(node.getAttribute('line_id'))
                != node.id) {

                console.log('node not in hash; removing line_id');
                node.setAttribute('line_id', '');
                this.unsavedChanges.push(node.id);
            }

            /* assure all changed nodes in unsavedChanges - shouldn't be necessary */
            if (   node.getAttribute('changed') == '1'
                && this.unsavedChanges.indexOf(node.id) == -1) {

                console.log('adding node to unsavedChanges: ' + node.id);
                this.unsavedChanges.push(node.id);
            }

            /* new nodes */
            if (!node.getAttribute('line_id')) this.newNodes = true;
        }.bind(this));
    },

    autosave: function() {
        if(doc.editor.isDirty() || !doc.editor.isNotDirty) {
            doc.editor.isNotDirty = true;

            doc.outline.updateIds();
            doc.rightRail.sync();
            var saveButton = $('save_button');
            saveButton.disabled = true;
            saveButton.innerHTML = 'Saving';
            saveButton.addClassName("saving");

            /* save */
            new Ajax.Request('/documents/'+this.documentId, {
                method: 'put',
                parameters: {'html': doc.editor.getContent(),
                             'name': $('document_name').value,
                             'delete_nodes': this.deleteNodes.toString()},

                onCreate: function() {

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
                }.bind(this)
            });
        }
        else {
            console.log("don't save");
        }
    },

    onChange: function(target, e) {
        if (e && e.keyCode >= 37 && e.keyCode <= 40) return;

        if (target) {
            if (target.tagName != "P" && target.tagName != "LI" && target.tagName != "DIV")  {
                target = Element.up(target, "p, li, div");
                if (!target) {
                    console.log("invalid onChange target");
                    return;
                }
            }

            Element.addClassName(target, 'changed');
            Element.writeAttribute(target, 'changed', "1");

            /* new/existing card handling */
            var id = Element.readAttribute(target, 'id') || null;
            if (!id) {
                console.log("onchange no id");
                doc.rightRail.createCard(target);
            }
            else if (doc.iDoc.getElementById(id) != target) {
                console.log("not the same element");
                target.id = "";
                Element.removeClassName(target, "active");
                doc.rightRail.createCard(target);
            }
            else if(doc.rightRail.cards.get(id)) {
                console.log("onchange id");
                doc.rightRail.updateFocusCardWrapper(id, target);
            }
            else {
                console.log('error: node has id but no card exists');
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
            console.log("call deactivate (2) on card: " + this.cardNumber);
            doc.rightRail.cards.get(domId).deactivate();
        }

        /* autosave */
        node.setAttribute('changed', '1');
        this.unsavedChanges.push(node.id);
        this.autosave();

        /* refocus on editor */
        doc.editor.focus();
    }
});

var cRightRail = Class.create({

    cardCount: 1,
    cards: new Hash(),
    inFocus: null,

    updateFocusCardTimer: null,

    build: function() {

        /* set card count */
        Element.select(doc.outline.iDoc, 'li, p, div').each(function (node) {
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
            && node.tagName.toUpperCase() != 'DIV') return null;

        Element.addClassName(node, "outline_node");

//        /* filter styles */
//        var style = Element.readAttribute(node, 'style');
//        console.log(style);
//        style = style.replace(/font[^;]+;/, "");
//        Element.writeAttribute(node, 'style', style);
//        console.log(style);

        //clear cloned node info if not first node with given id
        console.log("create card node_id: " + node.id);
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
    },

    focus: function(id) {

        //normalize id
        var cardId = doc.utilities.toCardId(id);

        //check card exists
        if (!$(cardId)) {
            console.log("error: can't focus on non-existent card");
            return;
        }

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
            else console.log('error: cannot unfocus previous card');
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
        var nodes = Element.select(doc.outline.iDoc, 'li, p, div')
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

        // @todo for now ignore contextualizing active card
        parser.parse(this, false, true);

        this.render(truncate);
    },

    activate: function() {
        this.active = true;
        console.log("activate function for card number: " + this.cardNumber);
        $('card_' + this.cardNumber).addClassName('card_active');
        var node = doc.outline.iDoc.getElementById("node_" + this.cardNumber);
        Element.addClassName(node, "active");
        doc.outline.onChange();
        this.render();
    },

    deactivate: function() {
        this.active = false;
        console.log("deactivate function for card number: " + this.cardNumber);
        $('card_' + this.cardNumber).removeClassName('card_active');
        var node = doc.outline.iDoc.getElementById("node_" + this.cardNumber);
        Element.removeClassName(node, "active");
        var truncate = !this.inFocus || this.inFocus.id != 'card_' + this.cardNumber;
        doc.outline.onChange();
        this.render(truncate);
    },

    render: function(truncate) {

        /* attempt autoactivate */
        if (this.autoActivate) {
            this.autoActivated = true;
            this.autoActivate = false;
            this.activate();
            this.elmntCard.down('input').checked = 'yes';
            var node = doc.outline.iDoc.getElementById('node_' + this.cardNumber);
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
                console.log("call deactivate (1) on card: " + this.cardNumber);
                console.log(this.back);
                console.log(this.text);
                console.log(this);
                this.deactivate();
                this.elmntCard.down('input').checked = '';
                var node = doc.outline.iDoc.getElementById('node_' + this.cardNumber);
                Element.removeClassName(node, "active");
            }
        }

        //no card to update
        else {
            console.log('error: cannot render - no card in dom to update')
            return;
        }

    },

    destroy: function() {
        try {
            Element.remove(this.elmntCard);
            doc.rightRail.cards.unset('node_' + this.cardNumber);
        }
        catch (err) {
            console.log("unable to destroy node. exception thrown");
        }
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

            // @todo create previous card if does not exist
            console.log('error: no previous card but there should be!');

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
    },

    showTitle: function() {
        var doc_name = $("document_name");
        if (doc_name.prototip) $('document_name').prototip.show();
        else {
            new Tip(doc_name, $("tip_title"), {
                title: 'Getting started (1 of 4)',
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

    showEditor: function() {
        var editorIfr = $("editor_ifr");
        new Tip(editorIfr, $("tip_editor"), {
            title: 'Getting started (2 of 4)',
            style: 'protogrey',
            closeButton:true,
            hook: {target: 'topLeft', tip: 'topLeft'},
            offset: {x: 20, y: 20},
            hideOn: false,
            showOn:false
        });
        Tips.hideAll();
        editorIfr.prototip.show();
    },

    showCards: function() {
        var rightRail = $("right_rail");
        new Tip(rightRail, $("tip_cards"), {
            title: 'Getting started (3 of 4)',
            style: 'protogrey',
            closeButton:true,
            hook: {target: 'bottomLeft', tip: 'bottomLeft'},
            offset: {x: 11, y: -11},
            hideOn: false,
            showOn:false
        });
        Tips.hideAll()
        rightRail.prototip.show();
    },

    showReview: function() {
        var reviewButton = $("review_button");
        new Tip(reviewButton, $("tip_review"), {
            title: 'Getting started (4 of 4)',
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
    },

    restartTour: function () {
        Tips.hideAll()
        this.showTitle();
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
