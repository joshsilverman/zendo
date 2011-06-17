var cClassSelector = Class.create({

    selected: null,

    initialize: function() {

        /* append new folder */
        this._appendNewFolderOption();

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
        new Dialog.Box('new_folder_menu');
        $('new_folder_menu').show();
        $('create_tag_submit').observe('click', function() {
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
    },

    /* create tag and assign document to it if id provided */
    createAndAssignTag: function() {

        var params = {"name": $('tag_name').value};
        if ($('line_ids')) params["doc_id"] = $("doc_id").innerHTML;

        new Ajax.Request('/tags/create_and_assign', {
            method: 'post',
            parameters: params,
            onCreate: function() {
                $('tag_id').disabled = true;
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
                $('tag_id').disabled = false;
                $('new_folder_menu').hide();
            }
        });
    }
});