{ObjectID, MongoClient} = require 'mongodb'
{EventEmitter} = require 'events'
{en: lingo} = require 'lingo'
async = require 'async'
_ = require 'underscore'

utils = require './utils'

{pass, dotGet, dotSet, dotPick, randomVersion, addVersionForUpdates} = utils
{formatValidators, isModel, isEmbeddedDocument, addPrefixForUpdates} = utils
{isEmbeddedArray, forEachPath, isDocument, isInstanceOf} = utils

###
Public: Mabolo Model

Define model methods and instance methods:

```coffee
User.findByName = (name) ->
  arguments[0] = username: name
  @findOne.apply @, arguments

User::getName = ->
  return @username
```

###
class Model
  ###
  Section: Create document

  Create doucment and save to MongoDB:

      user = new User
        username: 'jysperm'

      user.save (err) ->
        console.log @_id

  Mabolo will queue your operators before connecting to MongoDB.

  Or use `User.create`:

      User.create
        username: 'jysperm'
      , (err, user) ->
        console.log user._id

  ###

  ###
  Public: Constructor

  ```coffee
  new Model document
  ```

  * `document` {Object}

  ###
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

  ###
  Public: Create

  ```coffee
  Model.create document, [callback]
  ```

  * `document` {Object}
  * `callback` (optional) {Function}

  ###
  @create: (document, callback) ->
    document = new @ document

    document.save (err) ->
      callback.call document, err, document

  ###
  Public: Transform

  ```coffee
  Model.transform document
  Model.transform documents
  ```

  * `document` (optional) {Object} or {Array}

  return {Model} document or {Array} of {Model} documents

  ###
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

  ###
  Section: Query from MongoDB
  ###

  ###
  Public: Find

      Model.find query, [options], [callback]

  * `query` (optional) {Object}
  * `options` (optional) {Object}
  * `callback` (optional) {Function} `(err, documents) ->`

  Find documents from MongoDB:

      User.find (err, users) ->
        console.log users[0].username

  {Model.find} will callback with array of data, instead of a Cursor.

  ###
  @find: ->
    self = @

    @execute('find').apply null, @injectCallback arguments, (err, cursor) ->
      if err
        @callback err
      else
        cursor.toArray (err, documents) =>
          @callback err, self.transform documents

  ###
  Public: Find one

      Model.findOne query, [options], [callback]

  * `query` (optional) {Object}
  * `options` (optional) {Object}
  * `callback` (optional) {Function} `(err, document) ->`

  ###
  @findOne: ->
    @execute('findOne').apply null, @injectCallback arguments

  ###
  Public: Find by id

      Model.findById id, [options], [callback]

  * `id` {ObjectID}
  * `options` (optional) {Object}
  * `callback` (optional) {Function} `(err, document) ->`

  ###
  @findById: (id) ->
    try
      arguments[0] = _id: ObjectID id
      @findOne.apply @, arguments
    catch err
      (_.last arguments) err

  ###
  Public: Count

  ```coffee
  Model.count query, [options], [callback]
  ```

  * `query` (optional) {Object}
  * `callback` (optional) {Function} `(err, document) ->`

  ###
  @count: ->
    @execute('count').apply null, @injectCallback arguments

  ###
  Public: Aggregate

  ```coffee
  Model.aggregate commands, [options], [callback]
  ```

  * `commands` {Array}
  * `options` (optional) {Object}
  * `callback` (optional) {Function}

  ###
  @aggregate: ->
    @execute('aggregate').apply null, arguments

  ###
  Section: Manage MongoDB Collection
  ###

  ###
  Public: Get Collection

  return Collection of node-mongodb-native or {undefined}
  ###
  @getCollection: ->
    return @_mabolo.db?.collection @_options.collection_name

  ###
  Public: Ensure index

  ```coffee
  Model.ensureIndex fields, [options], [callback]
  ```

  * `fileds` {Object}
  * `options` (optional) {Object}
  * `callback` (optional) {Function}

  ###
  @ensureIndex: ->
    @execute('ensureIndex').apply null, arguments

  ###
  Section: Update MongoDB
  ###

  ###
  Public: Update

  ```coffee
  Model.update query, updates, [options], [callback]
  ```

  * `query` {Object}
  * `updates` {Object}
  * `options` (optional) {Object}
  * `callback` (optional) {Function}

  ###
  @update: (query, updates) ->
    addVersionForUpdates updates
    @execute('update').apply null, arguments

  ###
  Public: Remove

  ```coffee
  Model.remove query, [options], [callback]
  ```

  * `query` {Object}
  * `options` (optional) {Object}
  * `callback` (optional) {Function}

  ###
  @remove: ->
    @execute('remove').apply null, arguments

  ###
  Public: Fine one and update

  ```coffee
  Model.findOneAndUpdate query, updates, [options], [callback]
  ```

  * `query` {Object}
  * `updates` {Object}
  * `options` (optional) {Object}

    * `sort` (optional) {Object} `{field: -1}`
    * `new` (optional) {Boolean} default `true`

  * `callback` (optional) {Function} `(err, document) ->`

  ###
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

  ###
  Public: Find by id and update

  ```coffee
  Model.findByIdAndUpdate id, updates, [options], [callback]
  ```

  * `id` {ObjectID}
  * `updates` {Object}
  * `options` (optional) {Object}

    * `new` (optional) {Boolean} default `true`

  * `callback` (optional) {Function} `(err, document) ->`

  ###
  @findByIdAndUpdate: (id) ->
    try
      arguments[0] = _id: ObjectID id
      @findOneAndUpdate.apply @, arguments
    catch err
      (_.last arguments) err

  ###
  Public: Find one and remove

  ```coffee
  Model.findOneAndRemove query, [options], [callback]
  ```

  * `query` {Object}
  * `options` (optional) {Object}

    * `sort` (optional) {Object} `{field: -1}`

  * `callback` (optional) {Function} `(err, document) ->`

  ###
  @findOneAndRemove: (query, options, _callback) ->
    self = @

    callback = _.last @injectCallback arguments, (err, document) ->
      @callback err, self.transform document

    unless _callback
      options =
        sort: null

    @execute('findAndRemove') query, options.sort, options, callback

  ###
  Public: Find by id and remove

  ```coffee
  Model.findByIdAndRemove id, [options], [callback]
  ```

  * `id` {ObjectID}
  * `options` (optional) {Object}
  * `callback` (optional) {Function} `(err, document) ->`

  ###
  @findByIdAndRemove: (id) ->
    try
      arguments[0] = _id: ObjectID id
      @findOneAndRemove.apply @, arguments
    catch err
      (_.last arguments) err

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

  ###
  Section: Document Methods
  ###

  ###
  Public: Validate

  ```coffee
  document.validate [callback]
  document.embedded.validate [callback]
  ```

  * `callback` (optional) {Function} `(err) ->`

  ###
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

  ###
  Public: Save

  ```coffee
  document.save [callback]
  ```

  * `callback` (optional) {Function} `(err) ->`

  ###
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

  ###
  Public: To Object

  ```coffee
  document.toObject()
  ```

  return {Object}

  ###
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

  ###
  Public: Update

  ```coffee
  document.update updates, [options], [callback]
  ```

  * `updates` {Object}
  * `options` {optional} {Object}

    * `new` (optional) {Boolean} default `true`

  * `callback` (optional) {Function} `(err) ->`

  ###
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

  ###
  Public: Modify

  ```coffee
  document.modify modifier, [callback]
  ```

  * `commit` {Function} `(err) ->`
  * `callback` (optional) {Function} `(err) ->`

  Modify exists document atomically:

      user.modify (commit) ->
        @name = 'jysperm'
        commit()
      , (err) ->

  The document will rollback to latest version if validating fail or `commit` received an err.

  ###
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
      model.findById @_id, (err, result) ->
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
          , document, (err, result) ->
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

  ###
  Public: Remove

  ```coffee
  document.remove [callback]
  document.embedded.remove [callback]
  ```

  * `callback` (optional) {Function} `(err, result) ->`

  ###
  remove: (callback) ->
    # TODO: sub-Model
    @_isRemoved = true

    @constructor.remove _id: @_id, ->
      callback.apply null, arguments

  ###
  Public: Parent

  ```coffee
  document.parent()
  ```

  return parent document {Object}

  ## Embedded Document

      Token = mabolo.model 'Token',
        code: String

      User = mabolo.model 'User',
        username: String
        last_token: Token
        tokens: [Token]
        tags: [String]

  * Every embedded document has a `_id` and `__v`
  * Validators of embedded document will be run after parent document
  * Embedded document will be create when parent document created
  * `String`, `Number`, `Date`, `ObjectID` also can be used as an Model

  You can use `parent()` to get parent document:

      Token::revoke = (callback) ->
        @parent().update
          $pull:
            tokens:
              code: @code
        , callback

  ###
  parent: ->
    return @_parent

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

# Public: ObjectID from node-mongodb-native
class ObjectID

# Public: Mabolo
module.exports = class Mabolo extends EventEmitter
  db: null
  models: {}

  ObjectID: ObjectID

  ###
  Public: Create a new Mabolo instance

  * `uri` (optional) {String} uri of MongoDB

  ```coffee
  new Mabolo()
  new Mabolo 'mongodb://localhost/test'
  ```
  ###
  constructor: (uri) ->
    @connect uri if uri

  ###
  Public: Connect to MongoDB

  * `uri` {String} uri of MongoDB
  * `callback` (optional) {Function}

    * `err` {Error}
    * `db` Db from node-mongodb-native
  ###
  connect: (uri, callback = -> ) ->
    MongoClient.connect uri, (err, db) =>
      if err
        @emit 'error', err

      else
        @db = db
        @emit 'connected', db

      callback err, db

  ###
  Public: Create a Mabolo Model

  * `name` {String} a camelcase model name, like `Account`
  * `schema` {Object}

    * `type` {String}, {Number}, {Date}, {Boolean} or {ObjectID}
    * `default` (optional) A value or a {Function}
    * `enum` (optional) {Array} of values
    * `regex` (optional) {RegExp}
    * `required` (optional) {Boolean}
    * `validator` (optional) {Function}, {Array} or {Object}

  * `options` (optional) {Object}

    * `collection_name` {String} overwrite default collection name
    * `strict_pick` {Boolean} only store defined fields to database, default `true`

  Basic usages:

  ```coffee
  User = mabolo.model 'User',
    username: String
  ```

  Default value for field:

  ```coffee
  User = mabolo.model 'User',
    full_name:
      default: 'none'
  ```

  Multi-level path:

  ```coffee
  User = mabolo.model 'User',
    'name.full':
      default: 'none'
  ```

  Define built-in validator for field:

  ```coffee
  User = mabolo.model 'User',
    username:
      type: String
      enum: ['tomato', 'potato']
      regex: /^[a-z]{3,8}$/
      required: true
  ```

  Define your own validator:

  ```coffee
  User = mabolo.model 'User',
    username:
      validator: (username) ->
        return /^[a-z]{3,8}$/.test username
  ```

  Or asynchronous validator:

  ```coffee
  User = mabolo.model 'User',
    username:
      validator: fs.exists
  ```

  Multi-validator:

  `validator` can be:

  * {Function}

    * synchronous, return err if fail: `(value) ->`
    * asynchronous, callback err if fail: `(value, callback) ->`

  * {Array} of {Function}
  * {Object} of {Function}

  ```coffee
  User = mabolo.model 'User',
    username:
      validator:
        character: (username) -> /^[a-z]+$/.test username
        length: (username) -> 3 < username.length < 8
  ```

  `character` and `length` will be included in error message.

  ###
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
