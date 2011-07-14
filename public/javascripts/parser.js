var cParser = Class.create({

    docHtml: null, /* clone */
    iDoc: null,
    line:null,

    parse: function(Card, contextualize, ellipsize) {

//        console.log("parse");

        //pull card text from doc if text is blank
        this._identifyDoc(Card);
        if (Card.text == null) Card.text = "";

        if (this._parseDash(Card)) {}
        else if (this._parseStrong(Card)) {}
        else if (this._parseUnderline(Card)) {
//            console.log('parsed underline');
        }
        //no match
        else {
            //console.log('not parsable...');
            Card.front = Card.text;
            Card.back = '';
        }

        /* set simpleFront on card before attempting to contextualize*/
        Card.simpleFront = Card.front;

        /* add context to front if showContext set to true */
        if (contextualize) this._contextualize(Card);
        else if (ellipsize) this._ellipsize(Card);
    },

    _contextualize: function(Card) {

        /* identify doc and line */
        this._identifyDoc(Card);

        /* display properties for cue */
        if (!this.line) {
//            console.log(Card);
//            console.log(this.line);
            return
        }
        if (this.line.tagName == 'LI') {

            /* traverse anscestors */
            Element.ancestors(this.line).each(function(ancestor) {
                if (ancestor.tagName == 'LI') Element.setStyle(ancestor, {'display':'list-item'});
                else Element.setStyle(ancestor, {'display':'block'});});

            /* set line display block/list-item based on exists ancestors */
            if (Element.ancestors(this.line).length > 2) Element.setStyle(this.line, {'display':'list-item'});
            else {
                Element.setStyle(this.line, {'display':'block'});
                Element.setStyle(this.line, {'display':'block', 'textAlign': 'center'});
            }

            Card.front = this.docHtml;
        }
        else {
            Element.setStyle(this.line, {'display':'block', 'textAlign': 'center'});
            Card.front = this.line;
        }
        Element.addClassName(this.line, 'card_front_cue')
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
        //look for document_123 tag
        this.docHtml = this.iDoc = $('document_' + Card.documentId);

        //or look for ckeditor

        if (!this.docHtml && window['doc'] && doc.outline) {
            this.docHtml = doc.outline.iDoc.body;
            this.iDoc = doc.iDoc;
//            console.log(this.docHtml);
        }
        if (!this.docHtml) return;

        this.docHtml = Element.clone(this.docHtml, true)
        this.docHtml.id = '';

        /* locate adjust line node */
        this.line = Element.select(this.docHtml, '#' + Card.domId);
        if (!this.line) {
//            console.log('#' + Card.domId);
        }
        if (this.line.length == 0) return;
        Card.text = this.line[0].innerHTML.split(/<(?:li|ol|ul|p)/)[0];
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

        if (node && node.nodeName == "STRONG") {

            var term = Card.text.gsub(/<[^>]*>/, '').strip().gsub(/\s/, "_");
            term = term.underscore();
            term = term.charAt(0).toUpperCase() + term.slice(1);

            if (term.match(/Figure|Table/)) return false;

            if (node.getAttribute('def') || node.getAttribute('def') == "") {
                Card.front = Card.text
                Card.back = "";
                if (node.getAttribute('img_src')) 
                    Card.back += "<img src='" + node.getAttribute('img_src') + "'>";
                Card.back += node.getAttribute('def');
            }
            else {
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
                        node.setAttribute('def', transport.responseJSON['description']);
                        node.setAttribute('img_src', transport.responseJSON['image']);

                        Card.front = Card.text
                        Card.back = "";
                        if (node.getAttribute('img_src'))
                            Card.back += "<img src='" + transport.responseJSON['image'] + "'>";
                        Card.back += transport.responseJSON['description'];
                        Card.render();
                    },
                    onFailure: function() {
                        Card.back = '';
                        Card.render();
                    },
                    onComplete: function() {
                        if (doc.outline) doc.outline.change(node);
                    }
                });
            }
            return true;
        }
    },

    _parseUnderline: function(Card) {
        try {
            var node = Element.select(this.docHtml, '#' + Card.domId)[0];
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
    }
});