var cParser = Class.create({

    iDocClone: null, /* clone */
    iDoc: null,
    line:null,
    ajaxCalls: [],
    ajaxEmptyCount: 0, /* consecutive empty queue tests */

    initialize: function() {
      /* start ajax invoker */
      this.invokeAjax();
    },

    parse: function(Card, ellipsize) {

        //pull card text from doc if text is blank
        this._identifyDoc(Card);
        if (Card.text == null) Card.text = "";

        if (this._parseDash(Card)) {}
        else if (this._parseStrong(Card)) {}
//        else if (this._parseUnderline(Card)) {}
        //no match
        else {
            //console.log('not parsable...');
            Card.front = Card.text;
            Card.back = '';
        }

        /* set simpleFront */
        Card.simpleFront = Card.front;

        /* ellipsize */
        if (ellipsize) this._ellipsize(Card);
    },

    _ellipsize: function(Card) {

        /* identify doc and line */
        this._identifyDoc(Card);
        if (this.line.tagName != 'LI') return;
        Card.front = this.line;
        var grandparent = Element.up(Element.up(this.line));
        if (grandparent && grandparent.tagName == 'LI')
            Card.front = "<ul style='text-align:left; color:#666;'><li>...<ul><li style='color:black;'>"+Card.front.innerHTML+"</li><ul></li></ul>"
    },

    _identifyDoc: function(Card) {

        /* set docHtml var */
        if ($('document_' + Card.documentId)) {
            this.iDocClone = this.iDoc = Element.clone($('document_' + Card.documentId), true);
            this.iDocClone.id = '';
        }
        else this.iDoc = doc.iDoc;

        if (!this.iDoc && !this.iDocClone) return;

        /* locate adjust line node */
        this.line = Element.select(this.docHtml, '#' + Card.domId);
        if (this.line.length == 0) return;
        Card.text = this.line[0].innerHTML.split(/<(?:li|ol|ul|p|strong|b)/)[0];
        this.line = Element.extend(this.line[0]);
        Element.update(this.line, Card.front);
    },

    _parseDash: function(Card) {

        var defParts = Card.text.split(/(?:\s+-+\s+|-+\s+|\s+-+)/);
        if (defParts.length > 1) {

            //set autoActivate member if this is the first time text has been parsable
            if (!Card.back && !Card.active) {
//                console.log("dash parser auto-activates card number: " + Card.cardNumber);
                Card.autoActivate = true;
            }

            Card.front = defParts[0];
            Card.back = defParts.slice(1).join(' - ').unescapeHTML();
            if (Card.back == '') Card.back = ' - ';
            return true;
        }
    },

    _parseStrong: function(Card) {

        try {var node = Element.select(this.iDoc, '#' + Card.domId)[0];}
        catch (e) {}

        if (node && (node.nodeName == "STRONG" || node.nodeName == "B")) {

            /* @ugly this shouldn't be here... ugh */
//
//            console.log(node);
//            return;

            if (node.getAttribute('changed') != '1' && Element.hasClassName(node, 'not-found')) {
                $('card_' + Card.cardNumber).addClassName('not-found');
                Card.front = Card.text
                Card.back = '';
                Card.render();
            }
            else if (node.getAttribute('changed') != '1' && (node.getAttribute('def') || node.getAttribute('def') == "")) {
                Card.front = Card.text
                Card.back = "";
                if (node.getAttribute('img_src')) 
                    Card.back += "<img src='" + node.getAttribute('img_src') + "'>";
                if (node.getAttribute('def')) Card.back += node.getAttribute('def');
            }
            else {

                /* temp loading */
                if (Card['render']) {
                    Card.front = '<img alt="loading" src="/images/shared/fb-loader.gif" style="border:none !important;">';
                    Card.back = '';
                    console.log(Card);
                    Card.render();
                }

                var call = new Hash({
                    id: node.id,
                    func: function () {

                        /* check if node still exists */
                        try {
                            var node = Element.select(this.iDoc, '#' + Card.domId)[0];
                            if (!node) {
                                document.fire("lookup:complete");
                                return false;
                            }
                        }
                        catch (e) {
                            document.fire("lookup:complete");
                        }

                        /* focus on card before lookup */
                        doc.rightRail.focus(node.id);

                        var term = Card.text.gsub(/<[^>]*>/, '').strip().gsub(/\s/, "_").gsub(/\&nbsp;/, "");
                        term = term.underscore();
                        term = term.charAt(0).toUpperCase() + term.slice(1);
                        if (term.match(/Figure|Table/)) return false;

                        new Ajax.Request("/terms/lookup/" + term, {
                        onCreate: function() {
                            Card.autoActivate = true;
                            //set autoActivate member if this is the first time text has been parsable
                            if (!Card.back && !Card.active) {
                                Card.autoActivate = true;
                            }
                            Card.front = Card.text
                            Card.back = '<img alt="loading" src="/images/shared/fb-loader.gif" style="border:none !important;">';
                            Card.render();
                        },
                        onSuccess: function(transport) {

                            node.setAttribute('def', transport.responseJSON['description'].gsub(/\(pronounced[^)]*\)/, ""));
                            node.setAttribute('img_src', transport.responseJSON['image']);

                            Card.front = Card.text
                            Card.back = "";
                            if (node.getAttribute('img_src'))
                                Card.back += "<img src='" + transport.responseJSON['image'] + "'>";
                            Card.back += transport.responseJSON['description'];

                            /* remove pronunciation notes */
                            Card.back = Card.back.gsub(/\(pronounced[^)]*\)/, "");

                            Card.activate();
                            node.setAttribute('changed', 1);
                            Element.addClassName(node, 'changed');
                            Element.removeClassName(node, 'not-found');
                            Card.render();
                        },
                        onFailure: function() {
                            $('card_' + Card.cardNumber).addClassName('not-found');
                            Element.addClassName(node, 'not-found');
                            Card.back = '';
                            node.setAttribute('changed', 1);
                            Element.addClassName(node, 'changed');
                            Card.render();
                        },
                        onComplete: function() {
                            if (doc.outline) {
                                doc.editor.isNotDirty = false;
                                doc.outline.autosave();
                            }
                            document.fire("lookup:complete");
                        }
                    });
                    return true;
                }.bind(this)});

                /* replace older calls if exists */
                var inserted = false;
                this.ajaxCalls.each(function(call, i) {
                    if (call.get('id') == node.id) {
                        this.ajaxCalls[i] = call;
                        inserted = true;
                    }
                }.bind(this));

                if (!inserted) this.ajaxCalls.push(call);
            }
            return true;
        }
    },

    _parseUnderline: function(Card) {
        try {
            var node = Element.select(this.iDoc, '#' + Card.domId)[0];
            Element.select(node, 'span').each(function(span) {
                if (Element.getStyle(span, 'text-decoration') == 'underline') {
                    Card.front = Card.text.gsub(span.innerHTML, "__________").unescapeHTML();
                    Card.back = Card.text;

                    if (!Card.back && !Card.active) {
//                        console.log("underline parser auto-activates card number: " + Card.cardNumber);
                        Card.autoActivate = true;
                    }
                    return true;
                }
            });
            if (Card.back) return true;
        }
        catch (e) {}
        return false;
    },

    invokeAjax: function() {

        /* check queue status */
        if (this.ajaxCalls.length == 0) this.ajaxEmptyCount++;
        else this.ajaxEmptyCount = 0;
        if (this.ajaxEmptyCount > 2) {
            document.fire("lookup:idle");
        }

        if (this.ajaxCalls.length > 0) {
            document.observe("lookup:complete", function() {
                document.stopObserving("lookup:complete");
                this.invokeAjax();
            }.bind(this));
            while (this.ajaxCalls.length > 0 && !this.ajaxCalls.shift().get('func').call()) {}
        }
        else {
            document.stopObserving("lookup:complete");
            this.invokeAjax.bind(this).delay(3);
        }


    }
});