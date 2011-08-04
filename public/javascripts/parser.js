var cParser = Class.create({

    iDocClone: null, /* clone */
    iDoc: null,
    line:null,

    parse: function(Card, ellipsize) {
        console.log(Card);
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

        /* set simpleFront */
        Card.simpleFront = Card.front;

        /* ellipsize */
        if (ellipsize) this._ellipsize(Card);

        console.log(Card);

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

            var term = Card.text.gsub(/<[^>]*>/, '').strip().gsub(/\s/, "_").gsub(/\&nbsp;/, "");
            term = term.underscore();
            term = term.charAt(0).toUpperCase() + term.slice(1);

            if (term.match(/Figure|Table/)) return false;

            /* @ugly this shouldn't be here... ugh */
            if (node.getAttribute('def') || node.getAttribute('def') == "") {
                Card.front = Card.text
                Card.back = "";
                if (node.getAttribute('img_src')) 
                    Card.back += "<img src='" + node.getAttribute('img_src') + "'>";
                Card.back += node.getAttribute('def');
            }
            else {

                jQuery.ajax({
                   url: "http://localhost:5000/topics/get/"+term+".json",
                   xhrFields: {
                      withCredentials: true
                   },
                    beforeSend: function() {
                        console.log("BEFORESEND");
                        Card.autoActivate = true;
                        //set autoActivate member if this is the first time text has been parsable
                        if (!Card.back && !Card.active) {
                            Card.autoActivate = true;
                        }
                        Card.front = Card.text
                        Card.back = '<img alt="loading" src="/images/shared/fb-loader.gif" style="border:none !important;">';
                        Card.render();
                    },
                    success: function(transport) {
                        console.log("SUCCESS");
                        console.log(transport.topic.description)
                        node.setAttribute('def', transport.topic.description);
                        node.setAttribute('img_src', transport.topic.img_url);
                        node.setAttribute('mc', true);

                        Card.front = Card.text
                        Card.back = "";
                        if (node.getAttribute('img_src'))
                            Card.back += "<img src='" + transport.topic.img_url + "'>";
                        Card.back += transport.topic.description;
                        Card.render();
                    },
                    error: function(transport) {
                        console.log(transport);
                        console.log("ERROR");
                        Card.back = '';
                        Card.render();
                    },
                    complete: function() {
                        console.log("COMPLETE");
                        if (doc.outline) {
                            doc.editor.isNotDirty = false;
                            doc.outline.autosave();
                        }
                    }
                });
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
    }
});