{ObjectID, MongoClient} = require 'mongodb'
{EventEmitter} = require 'events'
{en: lingo} = require 'lingo'
_ = require 'underscore'

class Model
  @initialize: (options) ->
    _.extend @, options,
      _collection: null
      _queued_operators: []

  @create: ->
    @execute('insert') @injectCallback arguments, (err, documents) ->
      @callback err, documents?[0]

  @count: ->
    @execute('count') @injectCallback arguments

  @find: ->
    self = @

    @execute('find') @injectCallback arguments, (err, cursor) ->
      return @callback err if err

      cursor.toArray (err, documents) =>
        @callback err, self.buildModel documents

  @findOne: ->
    @execute('findOne') @injectCallback arguments

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
    @execute('update') arguments

  @remove: ->
    @execute('remove') arguments

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
      next = ->
        callback.apply
          callback: ->
            original.apply self, arguments
        , arguments

      args[args.length - 1] = (err, document) =>
        next err, @buildModel document

    return args

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
      Model.apply @, arguments

    options = _.extend(
      collection_name: lingo.pluralize name.toLowerCase()
    , options)

    @models[name] = model

    @on 'connected', ->
      model.runQueuedOperators()

    Proto = ->
    Proto.constructor = model
    Proto.prototype = Model.prototype
    model.prototype = new Proto

    _.extend model, Model

    model.initialize
      _mabolo: @
      _name: name
      _schema: schema
      _options: options
      methods: model.prototype

    return model
