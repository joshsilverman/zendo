/* class declarations */
cDoc = Class.create({

    delay:0,
    next:1,

    initialize: function() {
      $$('.input')[0].observe('keypress', function(event){
        this.o = $$('.output')[0];
        if(event.keyCode == Event.KEY_RETURN) {
          this[this.next]();
          this.next++;
          Event.stop(event);
        }
      }.bind(this));
    },

    1:function() {
      $$('.1').each(function(elmnt) {
        elmnt.show();
        this.o.scrollTop = this.o.scrollHeight;
      }.bind(this))
    },

    2:function() {
      $$('.2').each(function(elmnt) {
        elmnt.show();
        this.o.scrollTop = this.o.scrollHeight;
      }.bind(this))
    },

    3:function() {
      $$('.3').each(function(elmnt) {
        elmnt.show();
        $$('.input')[0].update("");
        $$('.input')[0].focus();
        this.o.scrollTop = this.o.scrollHeight;
      }.bind(this))
    },

    4:function() {
      $$('.4').each(function(elmnt) {
        elmnt.show();
        $$('.input')[0].update("");
        $$('.input')[0].focus();
        this.o.scrollTop = this.o.scrollHeight;
      }.bind(this))
    },

    5:function() {
      $$('.5').each(function(elmnt) {
        elmnt.show();
        $$('.input')[0].update("");
        $$('.input')[0].focus();
        (function () {
          $$(".watermark-container")[0].hide();
          $$(".hm")[0].show();
        }).delay(1)
        this.o.scrollTop = this.o.scrollHeight;
      }.bind(this))
    },

    6:function() {
      $$('.6').each(function(elmnt) {
        elmnt.show();
        $$('.input')[0].update("");
        $$('.input')[0].focus();
        this.o.scrollTop = this.o.scrollHeight;
      }.bind(this))
    },

    7:function() {
      $$('.7').each(function(elmnt) {
        elmnt.show();
        $$('.input')[0].update("");
        $$('.input')[0].focus();
        this.o.scrollTop = this.o.scrollHeight;
      }.bind(this))
    },

    8:function() {
      $$('.8').each(function(elmnt) {
        elmnt.show();
        $$('.input')[0].update("");
        $$('.input')[0].focus();
        (function () {
          $$(".hm")[0].hide();
          $$(".article")[0].show();
        }).delay(1)
        this.o.scrollTop = this.o.scrollHeight;
      }.bind(this))
    },

    9:function() {
      $$('.9').each(function(elmnt) {
        elmnt.show();
        $$('.input')[0].update("");
        $$('.input')[0].focus();
        this.o.scrollTop = this.o.scrollHeight;
      }.bind(this))
    }
});

/* global objects */
document.observe('dom:loaded', function() {doc = new cDoc();});