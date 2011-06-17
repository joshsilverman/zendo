var cClassSelector = Class.create({
    docId:null,

    initialize: function(docId) {
        this.docId = (typeof docId == "undefined")? false : docId;
        /* collect class options */
        var selector = $$('#tag_id')[0];
        if (selector) {

            selector.observe('change', function(element) {
                this.changeClass(element);
            }.bind(this));
        }

        $$('#tag_id option').each(function(option) {
            if (option._selected == 'true') option.selected = true;
        });
    },

    changeClass: function(element) {

        var parameters = {};
        if(!this.docId){
           parameters['doc_id'] = $('doc_id').innerHTML;
           console.log('1st: '+parameters['doc_id']);
        } else {
           parameters['doc_id'] =  $('metainfo').getAttribute('doc_id');
           console.log('2nd: '+parameters['doc_id']);
        }
        var selected = element.target.select("option[selected]");
        if (selected.length > 0) parameters['tag_id'] = selected[0].value;
        else {
            console.log("error");
            return;
        }

        /* sample listener for moved callback */
        //document.observe("document:moved", function() {});

        new Ajax.Request('/documents/update_tag', {
            method: 'post',
            parameters: parameters,
            onCreate: function() {
                $('tag_id').disabled = true;
                $("doc_loading").setStyle({'visibility': 'visible'});
            },
            onFailure: function() {},
            onSuccess: function() {
                document.fire("document:moved");
                document.stopObserving("document:moved");
            },
            onComplete: function() {
                $("doc_loading").setStyle({'visibility': 'hidden'});
                $('tag_id').disabled = false;
            }
        });
    }
});