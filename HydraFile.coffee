_ = require('lodash')
fs= require('fs')
EventEmitter = require("events").EventEmitter
path= require('path')
mime = require('mime')
class HydraFile extends EventEmitter
  chunkSize:1000
  blockSize: 16
  file: null
  constructor:(file,db, options) ->
    super
    _.bindAll(@,'retreivedFromDb','incrementStoredChunks','chunkRetrieved','blockRetreived')
    throw 'invalid file path' if 'string' is not typeof file
    @stored=0
    @retrieved=0
    @db= db
    stat=fs.statSync(file)
    @file =fs.readFileSync(file)
    @manifest={name: path.basename(file), size: stat.size,  lastModifiedDate:stat.mtime, type: mime.lookup(file), content:[]}
  retrieveManifest:->
    n=0
    b=0
    @keyfix=String(@manifest.name + '-' + @manifest.lastModifiedDate )
    @manifest.chunks= Math.floor(@file.length/@chunkSize)
    @manifest.chunks++ if @file.length % @chunkSize != 0
    for i in [0..@file.length] by @chunkSize
      chunk=
        id: n
        block: b
        start: i
        end: i + @chunkSize
        key:String(@keyfix + '-block-' + b + '-' + 'chunk-' + n++)
      @manifest.content.push(chunk)
      @db.put {_id: chunk.key, buffer: @file.slice(i, i + @chunkSize)}, @incrementStoredChunks
      @manifest.blocks= b+1
      b++ if n % @blockSize == 0
  incrementStoredChunks:(err)->
    if err
      if err.status == 409
        @stored++
      else
        @emit('error', err)
    else
      @stored++
    @emit('stored', @manifest) if @stored == @manifest.chunks

  createFileFromDB:->
    @file=[]
    for chunk in @manifest.content
      @db.get chunk.key, @retreivedFromDb
  createFileFromDBByBlock:->
    for block in [0...@manifest.content.blocks]
      manifestBlock= _.where(@manifest.content, {block: block})
      console.log(manifestBlock)
      options=
        start:manifestBlock[0].key
        end:manifestBlock[manifestBlock.length-1].key
      that= @
      @db.createReadStream(options).on 'data',(data) ->
        that.retreivedFromDb(null,data.value,data.key)
  retreivedFromDb: (err, value)->
    if  not @file?
      @file= []
      @file.push(value.buffer)
    else
      @file.push(value.buffer)
    @emit('created', new Buffer(@file)) if @file.length >= @manifest.content.length
  chunkRetrieved: (err,chunk)->
    console.err(err) if err?
    @emit('chunk', chunk) if chunk?
  retreiveChunk:(id)->
    keys=_.pluck(@manifest.content,'key')
    key=_.filter(keys,(key)->
      regex= new RegExp('-chunk-' + id + '$')
      return regex.test(String(key))
    )[0]
    @db.get key, @chunkRetrieved

  blockRetreived:(err, block)->
    console.err(err) if err?
    @emit('block', block) if block?

  retreiveBlock:(id)->
    keys=_.pluck(@manifest.content,'key')
    blocks=_.filter(keys,(key)->
      regex= new RegExp('-block-' + id + '-chunk-')
      return regex.test(String(key))
    )
    options =
      keys: blocks
    @db.allDocs options, @blockRetreived

  getFile:->
    new Buffer(@file)
module.exports.HydraFile= HydraFile

