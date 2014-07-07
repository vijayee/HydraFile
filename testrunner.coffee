qunit=require('qunit')
HydraFile= require('./HydraFile.js').HydraFile
###
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

###
PouchDB= require('pouchdb')

db= new PouchDB('files')

hydraFile= new HydraFile('./tests/test-files/xhydra.png',db)
hydraFile.on 'stored',(manifest) ->
  console.log("storage complete")
  hydraFile.retreiveBlock(1)
hydraFile.on 'created',(file) ->
  console.log(file)
hydraFile.on 'chunk',(file) ->
  console.log(file)
hydraFile.on 'block',(file) ->
  console.log(file)
hydraFile.retrieveManifest()

