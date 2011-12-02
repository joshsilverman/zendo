/* class declarations */

cDoc = Class.create({

  initialize: function() {
    
  }
});

document.observe('dom:loaded', function() {doc = new cDoc});