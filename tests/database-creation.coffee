test "testing database creation", (assert) ->
  console.log('happened')
  db= new PouchDB('files')
  file= new HydraFile(null,null,db)
  equal(true,file.db?, "database should be created")