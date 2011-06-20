var cClassSelector = Class.create({
    docId:null,
    selected: null,

    initialize: function(docId) {

        /* append new folder */
        this._appendNewFolderOption();


        this.docId = (typeof docId == "undefined")? false : docId;
        /* collect class options */
        var selector = $$('#tag_id')[0];
        if (selector) {
            selector.observe('change', function(event) {
                this.changeClass(event);
            }.bind(this));
        }

        $$('#tag_id option').each(function(option) {
            if (option.selected) {
                this.selected = option;
            }
        }.bind(this));

        /* create new dialog box for new folder */
        console.log('create dialog');
        new Dialog.Box('new_folder_menu');
        $('create_tag_submit').observe('click', function() {
            console.log('yo!');
            this.createAndAssignTag();
        }.bind(this));
    },

    changeClass: function(event) {

        /* selected option item */
        var selected = event.target.select("option[selected]");
        if (selected.length > 0) selected = selected[0];
        else return;

        if (selected.id == 'new_folder_option') {
            $('new_folder_menu').show();
            $('new_folder_option').selected = false;
            this.selected.selected = true;
        }

        var parameters = {};
        parameters['doc_id'] = (this.docId) ? $('metainfo').getAttribute('doc_id') : $('doc_id').innerHTML;
        parameters['tag_id'] = selected.value;

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
    },

    _appendNewFolderOption: function() {
        if ($('tag_id'))
            $('tag_id').insert({bottom: new Element('option', {id: 'new_folder_option', style: 'color:green;'}).insert("new folder")});
    },

    /* create tag and assign document to it if id provided */
    createAndAssignTag: function() {

        var params = {"name": $('tag_name').value};
        if ($('line_ids')) params["doc_id"] = $("doc_id").innerHTML;

        new Ajax.Request('/tags/create_and_assign', {
            method: 'post',
            parameters: params,
            onCreate: function() {
                if ($('tag_id')) $('tag_id').disabled = true;
                $("new_tag_loading").setStyle({'visibility': 'visible'});
            },
            onFailure: function() {
                $("new_tag_loading").setStyle({'visibility': 'hidden'});

            },
            onSuccess: function(transport) {
                $("new_tag_loading").setStyle({'visibility': 'hidden'});
                
                /* update tags_json if present */
                if ($('tags_json')) $('tags_json').update(transport.responseText);

                /* append and select new tag */
                var newOption = new Element('option', {id: 'new_folder_option', selected:'1'}).insert($('tag_name').value);
                $('new_folder_option').insert({before: newOption});
                $('tag_name').value = ""
            },
            onComplete: function() {
                if ($('tag_id')) $('tag_id').disabled = false;
                $('new_folder_menu').hide();
            }
        });
        document.fire("document:new_folder_created");
        console.log('doc:nfc FIRED');
        document.stopObserving("document:new_folder_created");
        console.log('done!');
    }
});