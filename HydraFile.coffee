_ = require('lodash')
fs= require('fs')
EventEmitter = require("events").EventEmitter
path= require('path')
mime = require('mime')
class HydraFile
  chunkSize:1000
  blockSize: 16
  file: null
  constructor:(file,db, options) ->
    _.bindAll(@,'receivedFromDb')
    throw 'invalid file path' if 'string' is not typeof file

    @file =file
    @db= db
    stat=fs.statSync(file)
    @manifest={name: path.basename(file), size: stat.size,  lastModifiedDate:stat.mtime, type: mime.lookup(file)}
  retrieveManifest:->
    n=0
    b=0
    for i in [0..@file.byteLength] by @chunkSize
      chunk=
        id: n
        block: b
        start: i
        end: i + @chunkSize
        key:String(@manifest.name + '-' + @manifest.lastModifiedDate + '-block-' + b + '-' + 'chunk-' + n++)
      db.put {_id: chunk.key, buffer: file.slice(i, i + @chunkSize)}, (err)->
        console.error('Failed to store chunk!', err) if err
      @manifest.content.blocks= b+1
      b++ if n % @blockSize == 0
    @manifest
  createFileFromDB:->
    for chunk in @manifest.content
      db.get chunk.key, @receivedFromDb
  createFileFromDBByBlock:->
    for block in [0...@manifest.content.blocks]
      manifestBlock= _.where(@manifest.content, {block: block})
      console.log(manifestBlock)
      options=
        start:manifestBlock[0].key
        end:manifestBlock[manifestBlock.length-1].key
      that= @
      db.createReadStream(options).on 'data',(data) ->
        that.receivedFromDb(null,data.value,data.key)
  receivedFromDb: (err, value)->
    if  not @file?
      @file= []
      @file.push(value.buffer)
    else
      @file.push(value.buffer)
  getFile:->
    new Blob(@file)
exports.HydraFile= HydraFile

