// Generated by CoffeeScript 1.7.1
(function() {
  var HydraFile, PouchDB, db, hydraFile, qunit;

  qunit = require('qunit');

  HydraFile = require('./HydraFile.js').HydraFile;


  /*
  qunit.setup
    log:
      summary: true
      coverage: true
  
  qunit.run
    code: './hydra-file.js'
    tests:'./tests/database-creation.js'
  , ->
      console.log('db testing complete')
  
  qunit.run
    code:'./add.js'
    tests:'./tests/add-test.js'
  , ->
      console.log("add test complete")
   */

  PouchDB = require('pouchdb');

  db = new PouchDB('files');

  hydraFile = new HydraFile('./tests/test-files/xhydra.png', db);

  hydraFile.on('stored', function(manifest) {
    return console.log("storage complete");
  });

  hydraFile.retrieveManifest();

}).call(this);

//# sourceMappingURL=testrunner.map
