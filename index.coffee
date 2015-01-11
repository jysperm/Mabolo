{ObjectID, MongoClient} = require 'mongodb'
{EventEmitter} = require 'events'
{en: lingo} = require 'lingo'
_ = require 'underscore'

class Model
  @_mabolo: null
  @_name: null
  @_schema: null
  @_options: null

  @_collection: null
  @_queued_operators: []

  @create: ->
    @execute('insert').apply @, @injectCallback arguments, (err, documents) ->
      @callback err, documents?[0]

  @count: ->
    @execute('count').apply @, @injectCallback arguments

  @find: ->
    self = @

    @execute('find').apply @, @injectCallback arguments, (err, cursor) ->
      return @callback err if err

      cursor.toArray (err, documents) =>
        @callback err, self.buildModel documents

  @findOne: ->
    @execute('findOne').apply @, @injectCallback arguments

  @findById: (id) ->
    try
      id = ObjectID id
      arguments[0] = id
      @findOne.apply @, arguments
    catch err
      callback = _.last arguments
      callback err if callback

  @findOneAndUpdate: ->

  @findByIdAndUpdate: ->

  @findOneAndRemove: ->

  @findByIdAndRemove: ->

  @update: ->
    @execute('update').apply @, arguments

  @remove: ->
    @execute('remove').apply @, arguments

  @runQueuedOperators: ->
    @_collection = @getCollection()
    until _.isEmpty @_queued_operators
      @_queued_operators.shift()()

  @injectCallback: (args, callback) ->
    args = _.toArray args
    original = args[args.length - 1]
    self = @

    callback ?= ->
      @callback.apply @, arguments

    if _.isFunction original
      next = =>
        callback.apply
          callback: ->
            original.apply self, arguments
        , arguments

      args[args.length - 1] = (err, document) =>
        next err, @buildModel document

    return args

  @execute: (name) ->
    return =>
      @_collection[name].apply @_collection, arguments

  @getCollection: ->
    return @_mabolo.db?.collection @_options.collection_name

  @buildModel: (document) ->
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
    _.extend @, document

  toObject: ->
    return _.pick.apply @, [@].concat Object.getOwnPropertyNames @

  update: ->
    args = _.toArray arguments
    args.unshift _id: @_id
    console.log @constructor, args
    @constructor.update.apply @constructor, args

  validate: ->

  remove: ->

_.each [
  'create', 'count', 'find', 'findOne', 'findById', 'findOneAndUpdate', 'findByIdAndUpdate'
  'findByIdAndRemove', 'update', 'remove', 'findOneAndRemove'
], (name) ->
  original = Model[name]

  Model[name] = ->
    args = arguments
    self = @

    next = ->
      original.apply self, args

    if @getCollection()
      next()
    else
      @_queued_operators.push next

module.exports = class Mabolo extends EventEmitter
  db: null
  models: {}

  # uri: optional mongodb uri, if provided will automatically call `Mabolo.connect`
  constructor: (uri) ->
    if uri
      @connect uri

  connect: (uri, callback = ->) ->
    MongoClient.connect uri, (err, db) =>
      if err
        if @listeners 'error'
          @emit 'error', err
        else
          throw err

      else
        @db = db
        @emit 'connected', db

      callback err, db

  # name: a camelcase model name, like `Account`
  # schema: schema definition object
  # options.collection_name: overwrite default collection name
  model: (name, schema, options) ->
    model = ->
      @constructor = model
      Model.apply @, arguments

    options = _.extend(
      collection_name: lingo.pluralize name.toLowerCase()
    , options)

    @models[name] = model

    @on 'connected', ->
      model.runQueuedOperators()

    Proto = ->
    Proto.prototype = Model.prototype
    model.prototype = new Proto

    return _.extend model, Model,
      _mabolo: @
      _name: name
      _schema: schema
      _options: options
      methods: model.prototype
