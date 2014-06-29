// Generated by CoffeeScript 1.7.1
(function() {
  var EventEmitter, HydraFile, fs, mime, path, _;

  _ = require('lodash');

  fs = require('fs');

  EventEmitter = require("events").EventEmitter;

  path = require('path');

  mime = require('mime');

  HydraFile = (function() {
    HydraFile.prototype.chunkSize = 1000;

    HydraFile.prototype.blockSize = 16;

    HydraFile.prototype.file = null;

    function HydraFile(file, db, options) {
      var stat;
      _.bindAll(this, 'receivedFromDb');
      if ('string' === !typeof file) {
        throw 'invalid file path';
      }
      this.file = file;
      this.db = db;
      stat = fs.statSync(file);
      this.manifest = {
        name: path.basename(file),
        size: stat.size,
        lastModifiedDate: stat.mtime,
        type: mime.lookup(file)
      };
    }

    HydraFile.prototype.retrieveManifest = function() {
      var b, chunk, i, n, _i, _ref, _ref1;
      n = 0;
      b = 0;
      for (i = _i = 0, _ref = this.file.byteLength, _ref1 = this.chunkSize; _ref1 > 0 ? _i <= _ref : _i >= _ref; i = _i += _ref1) {
        chunk = {
          id: n,
          block: b,
          start: i,
          end: i + this.chunkSize,
          key: String(this.manifest.name + '-' + this.manifest.lastModifiedDate + '-block-' + b + '-' + 'chunk-' + n++)
        };
        db.put({
          _id: chunk.key,
          buffer: file.slice(i, i + this.chunkSize)
        }, function(err) {
          if (err) {
            return console.error('Failed to store chunk!', err);
          }
        });
        this.manifest.content.blocks = b + 1;
        if (n % this.blockSize === 0) {
          b++;
        }
      }
      return this.manifest;
    };

    HydraFile.prototype.createFileFromDB = function() {
      var chunk, _i, _len, _ref, _results;
      _ref = this.manifest.content;
      _results = [];
      for (_i = 0, _len = _ref.length; _i < _len; _i++) {
        chunk = _ref[_i];
        _results.push(db.get(chunk.key, this.receivedFromDb));
      }
      return _results;
    };

    HydraFile.prototype.createFileFromDBByBlock = function() {
      var block, manifestBlock, options, that, _i, _ref, _results;
      _results = [];
      for (block = _i = 0, _ref = this.manifest.content.blocks; 0 <= _ref ? _i < _ref : _i > _ref; block = 0 <= _ref ? ++_i : --_i) {
        manifestBlock = _.where(this.manifest.content, {
          block: block
        });
        console.log(manifestBlock);
        options = {
          start: manifestBlock[0].key,
          end: manifestBlock[manifestBlock.length - 1].key
        };
        that = this;
        _results.push(db.createReadStream(options).on('data', function(data) {
          return that.receivedFromDb(null, data.value, data.key);
        }));
      }
      return _results;
    };

    HydraFile.prototype.receivedFromDb = function(err, value) {
      if (this.file == null) {
        this.file = [];
        return this.file.push(value.buffer);
      } else {
        return this.file.push(value.buffer);
      }
    };

    HydraFile.prototype.getFile = function() {
      return new Blob(this.file);
    };

    return HydraFile;

  })();

  exports.HydraFile = HydraFile;

}).call(this);

//# sourceMappingURL=HydraFile.map
