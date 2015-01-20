{ObjectID, MongoClient} = require 'mongodb'
{EventEmitter} = require 'events'
{en: lingo} = require 'lingo'
crypto = require 'crypto'
async = require 'async'
_ = require 'underscore'

dotGet = (object, path) ->
  paths = path.split '.'
  ref = object

  for key in paths
    if ref[key] == undefined
      return undefined
    else
      ref = ref[key]

  return ref

dotSet = (object, path, value) ->
  paths = path.split '.'
  last_path = paths.pop()
  ref = object

  for key in paths
    ref[key] ?= {}
    ref = ref[key]

  ref[last_path] = value

dotPick = (object, keys) ->
  result = {}

  for key in keys
    if dotGet(object, key) != undefined
      dotSet result, key, dotGet(object, key)

  return result

randomVersion = ->
  return crypto.pseudoRandomBytes(4).toString 'hex'

addVersionForUpdates = (updates) ->
  is_atom_op = _.every _.keys(updates), (key) ->
    return key[0] == '$'

  if is_atom_op
    updates.$set ?= {}
    updates.$set['__v'] ?= randomVersion()
  else
    updates['__v'] ?= randomVersion()

formatValidators = (validators) ->
  if _.isFunction validators
    validators = [validators]

  else if !_.isArray(validators) and _.isObject(validators)
    validators = _.map validators, (validator, name) ->
      validator.validator_name = name
      return validator

  return validators

class Model
  @initialize: (options) ->
    _.extend @, options,
      _collection: null
      _queued_operators: []

    if @getCollection()
      @runQueuedOperators()

  # create document, callback
  # callback.this: document
  @create: (document, callback) ->
    document = new @ document

    document.save (err) ->
      callback.apply document, [err, document]

  # count query, callback
  # count query, options, callback
  # count callback
  # callback.this: model
  @count: ->
    @execute('count') @injectCallback arguments

  # find query, callback
  # find query, options, callback
  # find callback
  # callback.this: model
  @find: ->
    self = @

    @execute('find') @injectCallback arguments, (err, cursor) ->
      return @callback err if err

      cursor.toArray (err, documents) =>
        @callback err, self.buildDocument documents

  # findOne query, callback
  # findOne query, options, callback
  # findOne callback
  # callback.this: model
  @findOne: ->
    @execute('findOne') @injectCallback arguments

  # findById id, callback
  # findById id, options, callback
  # findById callback
  # callback.this: model
  @findById: (id) ->
    try
      arguments[0] = _id: ObjectID id
      @findOne.apply @, arguments
    catch err
      callback = _.last arguments
      callback err if _.isFunction callback

  # findOneAndUpdate query, updates, options, callback
  # findOneAndUpdate query, updates, callback
  # options.sort
  # options.new: default to true
  # callback.this: model
  @findOneAndUpdate: (query, updates, options, _callback) ->
    addVersionForUpdates updates
    self = @

    callback = _.last @injectCallback arguments, (err, document) ->
      @callback err, self.buildDocument document

    unless _callback
      options = {new: true, sort: []}

    @execute('findAndModify') [query, options.sort, updates, options, callback]

  # findByIdAndUpdate id, update, options, callback
  # findByIdAndUpdate id, update, callback
  # options.new: default to true
  # callback.this: model
  @findByIdAndUpdate: (id) ->
    try
      arguments[0] = _id: ObjectID id
      @findOneAndUpdate.apply @, arguments
    catch err
      callback = _.last arguments
      callback err if _.isFunction callback

  # findOneAndRemove query, options, callback
  # findOneAndRemove query, callback
  # options.sort
  # callback.this: model
  @findOneAndRemove: (query, options, _callback) ->
    self = @

    callback = _.last @injectCallback arguments, (err, document) ->
      @callback err, self.buildDocument document

    unless _callback
      options = {sort: []}

    @execute('findAndRemove') [query, options.sort, options, callback]

  # findByIdAndRemove id, options, callback
  # findByIdAndRemove id, callback
  # options.sort
  # callback.this: model
  @findByIdAndRemove: (id) ->
    try
      arguments[0] = _id: ObjectID id
      @findOneAndRemove.apply @, arguments
    catch err
      callback = _.last arguments
      callback err if _.isFunction callback

  # update query, updates, callback
  # update query, updates, options, callback
  # callback.this: model
  @update: (query, updates) ->
    addVersionForUpdates updates
    @execute('update') arguments

  # remove query, callback
  # remove query, options, callback
  # callback.this: model
  @remove: ->
    @execute('remove') arguments

  # private
  @injectCallback: (args, callback) ->
    args = _.toArray args
    original = args[args.length - 1]
    self = @

    callback ?= ->
      @callback.apply @, arguments

    if _.isFunction original
      next = ->
        callback.apply
          callback: ->
            original.apply self, arguments
        , arguments

      args[args.length - 1] = (err, document) =>
        next err, @buildDocument document

    return args

  # private
  @execute: (name) ->
    if @_collection
      return (args) =>
        @_collection[name].apply @_collection, args
    else
      return (args) =>
        @_queued_operators.push =>
          @_collection[name].apply @_collection, args

  @getCollection: ->
    return @_mabolo.db?.collection @_options.collection_name

  # private
  @runQueuedOperators: ->
    if @_queue_started
      return

    _.extend @,
      _queue_started: true
      _collection: @getCollection()

    until _.isEmpty @_queued_operators
      @_queued_operators.shift()()

  # buildDocument document
  # buildDocument documents
  @buildDocument: (document) ->
    if document?.cursorId?._bsontype
      return document

    else if _.isArray document
      return _.map document, (doc) =>
        return new @ doc

    else if _.isObject document
      return new @ document

    else
      return document

  constructor: (document) ->
    Object.defineProperties @,
      _isNew:
        writable: true
      _isRemoved:
        writable: true
      __v:
        writable: true

    _.extend @, document

    unless @_id
      @_isNew = true

    unless @__v
      @__v = randomVersion()

  toObject: ->
    return _.pick.apply @, [@].concat Object.keys @

  # update update, options, callback
  # update update, callback
  # options.new: default to true
  # callback.this: document
  update: (update, options, callback) ->
    args = _.toArray arguments
    args.unshift @_id

    original = _.last args
    args[args.length - 1] = (err, document) =>
      unless options.new == false
        _.extend @, document

      original.apply @, arguments

    @constructor.findByIdAndUpdate.apply @constructor, args

  # callback.this: document
  save: (_callback) ->
    model = @constructor

    if !@_isNew and @_isRemoved
      throw new Error 'Only supports save new document'

    for path, definition of model._schema
      {default: default_value} = definition

      if dotGet(@, path) == undefined and default_value != undefined
        if _.isFunction default_value
          default_value = default_value()
        else
          default_value = _.clone default_value

        dotSet @, path, default_value

    document = dotPick @toObject(), _.keys(model._schema)
    document.__v = @__v

    @validate (err) ->
      return _callback err if err

      callback = (err, documents) =>
        document = documents?[0]

        if document
          _.extend @, document

        _callback.apply @, [err, model.buildDocument document?[0]]

      model.execute('insert') [document, callback]

  # modifier(commit(err))
  # modifier.this: document
  # callback(err)
  # callback.this: document
  modify: (modifier, callback) ->
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
          document = dotPick @toObject(), _.keys(model._schema)

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

  # callback.this: document
  validate: (callback) ->
    error = (path, type, message) =>
      callback.apply @, [new Error "validating fail when `#{path}` #{type} #{message}"]

    # Built-in
    for path, definition of @constructor._schema
      value = dotGet @, path

      if value == undefined and !definition.required
        continue

      err = (message) ->
        error path, 'type', message

      if definition.type
        switch definition.type
          when String
            unless _.isString value
              return err 'is string'

          when Number
            unless _.isNumber value
              return err 'is number'

          when Date
            unless _.isDate value
              return err 'is date'

          when Boolean
            unless _.isBoolean value
              return err 'is boolean'

          when ObjectID
            unless value instanceof ObjectID
              return err 'is objectid'

          when Object

          else
            throw new Error "unknown filed type #{definition.type.toString()}}"

      if definition.enum
        unless value in definition.enum
          return error path, 'enum', "in [#{definition.enum.join ', '}]"

      if definition.regex
        unless definition.regex.test value
          return error path, 'regex', "match #{definition.regex}"

      # sync validator
      if definition.validator
        sync_validators = _.filter formatValidators(definition.validator), (validator) ->
          return validator.length != 2

        for validator in sync_validators
          unless validator.apply @, [value]
            return error path, 'validator(sync)', validator.validator_name

    # async validator
    async_validators = []

    for path, definition of @constructor._schema
      value = dotGet @, path

      if value == undefined and !definition.required
        continue

      async_validators = async_validators.concat _.filter formatValidators(definition.validator), (validator) ->
        validator.value = value
        validator.path = path
        return validator.length == 2

    async.each async_validators, (validator, callback) ->
      validator validator.value, (err) ->
        if err
          err = new Error "validating fail when `#{path}` validator(async) #{err}"

        callback err

    , (err) =>
      callback.apply @, [err]

  remove: (callback) ->
    @_isRemoved = true

    @constructor.remove _id: @_id, ->
      callback.apply null, arguments

module.exports = class Mabolo extends EventEmitter
  db: null
  models: {}

  ObjectID: ObjectID

  # uri: optional mongodb uri, if provided will automatically call `Mabolo.connect`
  constructor: (uri) ->
    if uri
      @connect uri

  connect: (uri, callback = ->) ->
    MongoClient.connect uri, (err, db) =>
      if err
        @emit 'error', err

      else
        @db = db
        @emit 'connected', db

      callback err, db

  # name: a camelcase model name, like `Account`
  # schema: schema definition object
  # options.collection_name: overwrite default collection name
  model: (name, schema, options) ->
    options = _.extend(
      collection_name: lingo.pluralize name.toLowerCase()
    , options)

    class model extends Model

    model.initialize
      _mabolo: @
      _name: name
      _schema: schema
      _options: options
      methods: model.prototype

    @models[name] = model

    @on 'connected', ->
      model.runQueuedOperators()

    return model
