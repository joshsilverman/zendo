var cClassSelector = Class.create({

    initialize: function() {

        /* append new folder */
        this._appendNewFolderOption();

        /* collect class options */
        var selector = $$('#tag_id')[0];
        if (selector) {
            console.log(selector);
            selector.observe('change', function(event) {
                this.changeClass(event);
            }.bind(this));
        }

        $$('#tag_id option').each(function(option) {
            if (option._selected == 'true') option.selected = true;
        });

        new Dialog.Box('new_folder_menu');
        $('new_folder_menu').show();
    },

    changeClass: function(event) {

        /* selected option item */
        var selected = event.target.select("option[selected]");
        if (selected.length > 0) selected = selected[0];
        else return;

        if (selected.id == 'new_folder_option') {
            console.log('new folder');
            return;
        }

        var parameters = {};
        parameters['doc_id'] = $('doc_id').innerHTML;
        parameters['tag_id'] = selected.value;
        
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
            },
            onComplete: function() {
                $("doc_loading").setStyle({'visibility': 'hidden'});
                $('tag_id').disabled = false;
            }
        });
    },

    _appendNewFolderOption: function() {
        $('tag_id').insert({bottom: new Element('option', {id: 'new_folder_option', style: 'color:green;'}).insert("new folder")});
    }
});