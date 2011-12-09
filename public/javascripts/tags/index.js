/* class declarations */

cDoc = Class.create({

  initialize: function() {
    window.onresize = AppUtilities.resizeContents;
    AppUtilities.resizeContents();
  }
});

document.observe('dom:loaded', function() {doc = new cDoc});