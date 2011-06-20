var Dialog = {};
Dialog.Box = Class.create();
Object.extend(Dialog.Box.prototype, {
    initialize: function(id) {
      this.createOverlay();

      this.dialog_box = $(id);
      this.dialog_box.show = this.show.bind(this);
      this.dialog_box.persistent_show = this.persistent_show.bind(this);
      this.dialog_box.hide = this.hide.bind(this);

      this.parent_element = this.dialog_box.parentNode;

      this.dialog_box.style.position = "absolute";

      var e_dims = Element.getDimensions(this.dialog_box);
      var b_dims = Element.getDimensions(this.overlay);

      this.dialog_box.style.left = ((b_dims.width/2) - (e_dims.width/2)) + 'px';
      this.dialog_box.style.top = this.getScrollTop() + ((this.winHeight() - (e_dims.width/2))/2) + 'px';
      this.dialog_box.style.zIndex = this.overlay.style.zIndex + 1;
    },

    createOverlay: function() {
      if($('dialog_overlay')) {
        this.overlay = $('dialog_overlay');
      } else {
        this.overlay = document.createElement('div');
        this.overlay.id = 'dialog_overlay';
        Object.extend(this.overlay.style, {
        	position: 'absolute',
        	top: 0,
        	left: 0,
        	zIndex: 90,
        	width: '100%',
        	backgroundColor: '#000',
        	display: 'none'
        });
        document.body.insertBefore(this.overlay, document.body.childNodes[0]);
      }
    },

    moveDialogBox: function(where) {
      Element.remove(this.dialog_box);
      if(where == 'back')
        this.dialog_box = this.parent_element.appendChild(this.dialog_box);
      else
        this.dialog_box = this.overlay.parentNode.insertBefore(this.dialog_box, this.overlay);
    },

    show: function() {
      this.overlay.style.height = this.bodyHeight()+'px';
      this.moveDialogBox('out');

      this.overlay.onclick = this.hide.bind(this);

      this.selectBoxes('hide');
      new Effect.Appear(this.overlay, {duration: 0.1, from: 0.0, to: 0.3});
      this.dialog_box.style.display = '';

    	this.dialog_box.style.left = '0px';

      var e_dims = Element.getDimensions(this.dialog_box);

    	this.dialog_box.style.left = ((this.winWidth()/2) - (e_dims.width)/2) + 'px';

      this.dialog_box.style.top = this.getScrollTop() + ((this.winHeight() - (e_dims.width/2))/2) + 'px';

    },

    getScrollTop: function() {
    	return (window.pageYOffset)?window.pageYOffset:(document.documentElement && document.documentElement.scrollTop)?document.documentElement.scrollTop:document.body.scrollTop;
    },

    persistent_show: function() {
      this.overlay.style.height = this.bodyHeight()+'px';
      this.moveDialogBox('out');

      this.selectBoxes('hide');
      new Effect.Appear(this.overlay, {duration: 0.1, from: 0.0, to: 0.3});

      this.dialog_box.style.display = '';
    	this.dialog_box.style.left = '0px';
      var e_dims = Element.getDimensions(this.dialog_box);
    	this.dialog_box.style.left = ((this.winWidth()/2) - (e_dims.width)/2) + 'px';

    },

    hide: function() {
      this.selectBoxes('show');
      new Effect.Fade(this.overlay, {duration: 0.1});
      this.dialog_box.style.display = 'none';
      this.moveDialogBox('back');
      $A(this.dialog_box.getElementsByTagName('input')).each(function(e){if(e.type!='submit')e.value=''});
    },

    selectBoxes: function(what) {
//      $A(document.getElementsByTagName('select')).each(function(select) {
//        Element[what](select);
//      });
//
//      if(what == 'hide')
//        $A(this.dialog_box.getElementsByTagName('select')).each(function(select){Element.show(select)})
    },

	bodyWidth: function() { return document.body.offsetWidth || window.innerWidth || document.documentElement.clientWidth || 0; },
	bodyHeight: function() { return document.body.offsetHeight || window.innerHeight || document.documentElement.clientHeight || 0; },

    winWidth: function() {
		 var viewportwidth;

		 // the more standards compliant browsers (mozilla/netscape/opera/IE7) use window.innerWidth and window.innerHeight

		 if (typeof window.innerWidth != 'undefined')
		 {
		      viewportwidth = window.innerWidth;
		 }

		// IE6 in standards compliant mode (i.e. with a valid doctype as the first line in the document)

		 else if (typeof document.documentElement != 'undefined' && typeof document.documentElement.clientWidth != 'undefined' && document.documentElement.clientWidth != 0)
		 {
		       viewportwidth = document.documentElement.clientWidth;
		 }

		 // older versions of IE

		 else
		 {
		       viewportwidth = document.getElementsByTagName('body')[0].clientWidth
		 }
		 return viewportwidth;

     },
    winHeight: function() {
		 var viewportheight;

		 // the more standards compliant browsers (mozilla/netscape/opera/IE7) use window.innerWidth and window.innerHeight

		 if (typeof window.innerHeight != 'undefined')
		 {
		      viewportheight = window.innerHeight
		 }

		// IE6 in standards compliant mode (i.e. with a valid doctype as the first line in the document)

		 else if (typeof document.documentElement != 'undefined' && typeof document.documentElement.clientHeight != 'undefined' && document.documentElement.clientHeight != 0)
		 {
		       viewportheight = document.documentElement.clientHeight;
		 }

		 // older versions of IE

		 else
		 {
		       viewportheight = document.getElementsByTagName('body')[0].clientHeight;
		 }
		 return viewportheight;

    }

}); 