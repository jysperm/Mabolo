{ObjectID, MongoClient} = require 'mongodb'
{EventEmitter} = require 'events'
{en: lingo} = require 'lingo'
async = require 'async'
_ = require 'underscore'

utils = require './utils'

{pass, dotGet, dotSet, dotPick, randomVersion, addVersionForUpdates} = utils
{formatValidators, isModel, isEmbeddedDocument, addPrefixForUpdates} = utils
{isEmbeddedArray, forEachPath, isDocument, isInstanceOf} = utils

class Model
  @initialize: (options) ->
    _.extend @, options,
      _collection: null
      _queued_operators: []

    if @getCollection()
      @runQueuedOperators()

  @execute: (name) ->
    collection = @_collection
    queued_operators = @_queued_operators

    if collection
      return ->
        collection[name].apply collection, arguments
    else
      return ->
        queued_operators.push ->
          collection[name].apply collection, arguments

  @runQueuedOperators: ->
    if @_queue_started
      return

    _.extend @,
      _queue_started: true
      _collection: @getCollection()

    until _.isEmpty @_queued_operators
      @_queued_operators.shift()()

  @injectCallback: (args, callback) ->
    args = _.toArray args
    _callback = args[args.length - 1]
    self = @

    callback ?= ->
      @callback.apply @, arguments

    if _.isFunction _callback
      next = ->
        callback.apply
          callback: ->
            _callback.apply self, arguments
        , arguments

      args[args.length - 1] = (err, document) =>
        next err, @transform document

    return args

  @getCollection: ->
    return @_mabolo.db?.collection @_options.collection_name

  @transform: (document) ->
    if document?.cursorId?._bsontype
      return document

    else if _.isArray document
      return _.map document, (doc) =>
        return new @ doc

    else if _.isObject document
      return new @ document

    else
      return document

  @create: (document, callback) ->
    document = new @ document

    document.save (err) ->
      callback.call document, err, document

  @ensureIndex: ->
    @execute('ensureIndex').apply null, arguments

  @aggregate: ->
    @execute('aggregate').apply null, arguments

  @count: ->
    @execute('count').apply null, @injectCallback arguments

  @find: ->
    self = @

    @execute('find').apply null, @injectCallback arguments, (err, cursor) ->
      if err
        @callback err
      else
        cursor.toArray (err, documents) =>
          @callback err, self.transform documents

  @findOne: ->
    @execute('findOne').apply null, @injectCallback arguments

  @findById: (id) ->
    try
      arguments[0] = _id: ObjectID id
      @findOne.apply @, arguments
    catch err
      (_.last arguments) err

  @findOneAndUpdate: (query, updates, options, _callback) ->
    addVersionForUpdates updates
    self = @

    callback = _.last @injectCallback arguments, (err, document) ->
      @callback err, self.transform document

    unless _callback
      options =
        new: true
        sort: null

    @execute('findAndModify') query, options.sort, updates, options, callback

  @findByIdAndUpdate: (id) ->
    try
      arguments[0] = _id: ObjectID id
      @findOneAndUpdate.apply @, arguments
    catch err
      (_.last arguments) err

  @findOneAndRemove: (query, options, _callback) ->
    self = @

    callback = _.last @injectCallback arguments, (err, document) ->
      @callback err, self.transform document

    unless _callback
      options =
        sort: null

    @execute('findAndRemove') query, options.sort, options, callback

  @findByIdAndRemove: (id) ->
    try
      arguments[0] = _id: ObjectID id
      @findOneAndRemove.apply @, arguments
    catch err
      (_.last arguments) err

  @update: (query, updates) ->
    addVersionForUpdates updates
    @execute('update').apply null, arguments

  @remove: ->
    @execute('remove').apply null, arguments

  constructor: (document) ->
    Object.defineProperties @,
      _isNew:
        writable: true
      _isRemoved:
        writable: true
      _parent:
        writable: true
      _path:
        writable: true
      _index:
        writable: true
      __v:
        writable: true

    _.extend @, document

    unless @_id
      @_isNew = true

      if @_parent
        @_id = ObjectID()

    unless @__v
      @__v = randomVersion()

    @transformSubDocuments()

  transformSubDocuments: ->
    model = @constructor

    forEachPath model, @, (path, value, definition, it) =>
      if it.isEmbeddedArrayPath()
        if value == undefined
          return it.dotSet []

        SubModel = it.getEmbeddedArrayModel()

        unless isModel SubModel
          return

        it.dotSet _.map value, (value, index) =>
          if isInstanceOf SubModel, value
            return value
          else
            a = new SubModel _.extend value,
              _parent: @
              _path: path
              _index: index

            return a

      else if it.isEmbeddedDocumentPath()
        if value in [null, undefined]
          return

        SubModel = it.getEmbeddedDocumentModel()

        if isInstanceOf SubModel, value
          return

        it.dotSet new SubModel _.extend value,
          _parent: @
          _path: path

  parent: ->
    return @_parent

  toObject: ->
    model = @constructor

    if model._options.strict_pick
      object = dotPick @, _.keys(model._schema)
    else
      object = _.pick.apply null, [@].concat Object.keys @

    forEachPath model, @, (path, value, definition, it) ->
      if it.isEmbeddedArrayPath()
        if isModel it.getEmbeddedArrayModel()
          dotSet object, path, _.map value, (item) ->
            if isDocument item
              return item.toObject()
            else
              return item

      else if it.isEmbeddedDocumentPath()
        if isModel it.getEmbeddedDocumentModel()
          if isDocument value
            dotSet object, path, value.toObject()

    return object

  update: (updates, options, callback) ->
    # TODO: sub-Model
    args = _.toArray arguments
    args.unshift @_id

    original = _.last args
    args[args.length - 1] = (err, document) =>
      unless options.new == false
        _.extend @, document

      original.apply @, arguments

    @constructor.findByIdAndUpdate.apply @constructor, args

  save: (callback) ->
    model = @constructor

    if !@_isNew and @_isRemoved
      throw new Error 'Cant save exists document'

    if @_parent
      throw new Error 'Cant save embedded document'

    forEachPath model, @, (path, value, definition, it) ->
      default_value = definition.default

      if value == undefined and default_value != undefined
        if _.isFunction default_value
          default_value = default_value()
        else
          default_value = _.clone default_value

        it.dotSet default_value

    if model._options.strict_pick
      document = dotPick @, _.keys model._schema
    else
      document = _.pick.apply null, [@].concat Object.keys @

    document.__v = @__v

    @validate (err) ->
      return callback err if err

      model.execute('insert') document, (err, documents) =>
        document = documents?[0]

        if document
          # TODO: multi-level version of _.extend
          _.extend @, document

        callback.call @, err

  modify: (modifier, callback) ->
    # TODO: sub-Model
    model = @constructor
    FINISHED = {}

    unless @_id
      throw new Error 'Document not yet exists in MongoDB'

    overwrite = (latest) =>
      for key in _.keys model._schema
        delete @[key]

      _.extend @, latest
      @__v = latest.__v

    rollback = (callback) =>
      model.findById @_id, (err, result) =>
        overwrite result
        callback()

    async.forever (next) =>
      modifier.call @, (err) =>
        if err
          return rollback ->
            next err

        @validate (err) ->
          if err
            return rollback ->
              next err

          original_v = @__v
          @__v = randomVersion()
          document = dotPick @, _.keys(model._schema)

          model.findOneAndUpdate
            _id: @_id
            __v: original_v
          , document, (err, result) =>
            if err
              rollback ->
                next err

            else if result
              next FINISHED

            else
              rollback next

    , (err) =>
      err = null if err == FINISHED
      callback.apply @, [err]

  validate: (callback) ->
    model = @constructor
    @transformSubDocuments()

    is_errored = false

    error = (path, type, message) =>
      is_errored = true
      callback.call @, new Error "validating fail on `#{path}` #{type} #{message}"

    sub_documents = []
    async_validators = []

    forEachPath model, @, (path, value, definition, it) ->
      if value in [null, undefined] and !definition.required
        return

      typeError = (message) ->
        error path, 'type', message

      if it.isEmbeddedArrayPath()
        Type = it.getEmbeddedArrayModel()

        for item in value
          if isInstanceOf Type, item
            if isDocument item
              sub_documents.push item
          else
            return typeError "is array of #{Type._name ? Type.name}"

        return

      if it.Type
        if isInstanceOf it.Type, value
          if it.isEmbeddedDocumentPath()
            sub_documents.push value
        else
          return typeError "is #{it.Type._name ? it.Type.name}"

      if definition.enum
        unless value in definition.enum
          return error path, 'enum', "in [#{definition.enum.join ', '}]"

      if definition.regex
        unless definition.regex.test value
          return error path, 'regex', "match #{definition.regex}"

      if definition.validator
        validators = formatValidators definition.validator

        sync_validators = _.filter validators, (validator) ->
          return validator.length != 2

        for validator in sync_validators
          unless validator.apply @, [value]
            return error path, 'validator(sync)', validator.validator_name

        async_validators = _.union async_validators, _.filter validators, (validator) ->
          unless validator.length == 2
            return false

          return _.extend validator,
            value: value
            path: path

    if is_errored
      return

    async.parallel [
      (callback) ->
        async.each sub_documents, (sub_document, callback) ->
          sub_document.validate callback
        , callback

      (callback) ->
        async.each async_validators, (validator, callback) ->
          validator validator.value, (err) ->
            {path, validator_name: name} = validator

            if err
              err = new Error "validating fail on `#{path}` #{name} #{err}"

            callback err

        , callback

    ], (err) =>
      callback.call @, err

  remove: (callback) ->
    # TODO: sub-Model
    @_isRemoved = true

    @constructor.remove _id: @_id, ->
      callback.apply null, arguments

module.exports = class Mabolo extends EventEmitter
  db: null
  models: {}

  ObjectID: ObjectID

  constructor: (uri) ->
    @connect uri if uri

  connect: (uri, callback = ->) ->
    MongoClient.connect uri, (err, db) =>
      if err
        @emit 'error', err

      else
        @db = db
        @emit 'connected', db

      callback err, db

  model: (name, schema, options) ->
    options = _.extend(
      collection_name: lingo.pluralize name.toLowerCase()
      strict_pick: true
    , options)

    class model extends Model

    model.initialize
      _mabolo: @
      _name: name
      _schema: schema
      _options: options

    @models[name] = model

    @on 'connected', ->
      model.runQueuedOperators()

    return model
