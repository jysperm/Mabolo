{ObjectID, MongoClient} = require 'mongodb'
{EventEmitter} = require 'events'
{en: lingo} = require 'lingo'
crypto = require 'crypto'
async = require 'async'
_ = require 'underscore'
Q = require 'q'

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

  ```coffee
  user = new User
    username: 'jysperm'

  user.save.then ->
    console.log user._id
  ```

  Mabolo will queue your operators before connecting to MongoDB.

  Or use `User.create`:

  ```coffee
  User.create
    username: 'jysperm'
  .then (user) ->
    console.log user._id
  ```

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
      # Does the document query from MongoDB
      _isNew:
        writable: true
      # Did the document removed from MongoDB
      _isRemoved:
        writable: true
      # The parent of this document
      _parent:
        writable: true
      # Path of embedded document or embedded array
      _path:
        writable: true
      # Index of embedded array
      _index:
        writable: true
      # Version to prevent conflict
      __v:
        writable: true

    _.extend @, document

    unless @_id
      @_isNew = true

      if @_parent
        @_id = ObjectID()

    unless @__v
      @__v = randomVersion()

    @transform()

  ###
  Public: Create

  ```coffee
  Model.create document, [callback]
  ```

  * `document` {Object}
  * `callback` (optional) {Function}

  return {Promise} `(document) ->`

  ###
  @create: (document, callback) ->
    document = new @ document

    return document.save().then ->
      return document
    .nodeify callback

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

  ```coffee
  Model.find query, [options], [callback]
  ```

  * `query` (optional) {Object}
  * `options` (optional) {Object}
  * `callback` (optional) {Function} `(err, documents) ->`

  Find documents from MongoDB:

  ```coffee
  User.find (err, users) ->
    console.log users[0].username
  ```

  {Model.find} will callback with array of data, instead of a Cursor.

  ###
  @find: ->
    {args, callback} = splitArguments arguments

    return @execute('find').apply(null, args).then (cursor) =>
      return Q.Promise (resolve, reject) =>
        cursor.toArray (err, documents) =>
          if err
            reject err
          else
            resolve @transform documents
    .nodeify callback

  ###
  Public: Find one

  ```coffee
  Model.findOne query, [options], [callback]
  ```

  * `query` (optional) {Object}
  * `options` (optional) {Object}
  * `callback` (optional) {Function} `(err, document) ->`

  ###
  @findOne: ->
    {args, callback} = splitArguments arguments
    return @execute('findOne').apply(null, args).nodeify callback

  ###
  Public: Find by id

  ```coffee
  Model.findById id, [options], [callback]
  ```

  * `id` {Mabolo::ObjectID} or {String}
  * `options` (optional) {Object}
  * `callback` (optional) {Function} `(err, document) ->`

  ###
  @findById: (id) ->
    {args, callback} = splitArguments arguments

    return Q.Promise (resolve, reject) =>
      args[0] = _id: ObjectID id
      @findOne.apply(@, args).then resolve, reject
    .nodeify callback

  ###
  Public: Count

  ```coffee
  Model.count query, [options], [callback]
  ```

  * `query` (optional) {Object}
  * `callback` (optional) {Function} `(err, document) ->`

  ###
  @count: ->
    {args, callback} = splitArguments arguments
    return @execute('count').apply(null, args).nodeify callback

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
    {args, callback} = splitArguments arguments
    return @execute('aggregate').apply(null, args).nodeify callback

  ###
  Section: Manage MongoDB Collection
  ###

  ###
  Public: Get Collection

  return {Promise} `(Collection) ->`
  ###
  @getCollection: ->
    return collection

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
    {args, callback} = splitArguments arguments
    return @execute('ensureIndex').apply(null, args).nodeify callback

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
    {args, callback} = splitArguments arguments
    return @execute('update').apply(null, args).nodeify callback

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
    {args, callback} = splitArguments arguments
    return @execute('remove').apply(null, args).nodeify callback

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
  @findOneAndUpdate: ->
    {args: [query, updates, options], callback} = splitArguments arguments
    addVersionForUpdates updates

    options ?=
      new: true
      sort: null

    return @execute('findAndModify')(query, options.sort, updates, options).nodeify callback

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
    {arg, callback} = splitArguments arguments

    return Q.Promise (resolve, reject) =>
      args[0] = _id: ObjectID id
      return @findOneAndUpdate.apply(@, args).then resolve, reject
    .nodeify callback

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
  @findOneAndRemove: ->
    {args: [query, options], callback} = splitArguments arguments

    options ?=
      sort: null

    return @execute('findAndRemove')(query, options.sort, options).nodeify callback

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
    {arg, callback} = splitArguments arguments

    return Q.Promise (resolve, reject) ->
      args[0] = _id: ObjectID id
      return @findOneAndRemove.apply(@, args).then resolve, reject
    .nodeify callback

  @initialize: (options) ->
    _.extend @, options

  @execute: (name) ->
    return =>
      modelOf(@).collection.then (collection) =>
        return Q.Promise (resolve, reject) =>
          collection[name] arguments..., (err, result) =>
            if err
              reject err
            else
              resolve @transform result

  ###
  Section: Document Methods
  ###

  ###
  Public: Validate

  ```coffee
  document.validate()
  document.embedded.validate()
  document.embedded[0].validate()
  ```

  * `callback` (optional) {Function} `(err) ->`

  ###
  validate: (callback) ->
    @transform()

    Q.all _.keys(schemaOf @).map (path) =>
      return validatePath @, path
    .nodeify callback

  ###
  Public: Save

  ```coffee
  document.save [callback]
  ```

  * `callback` (optional) {Function} `(err) ->`

  ###
  save: (callback) ->
    if !@_isNew and @_isRemoved
      return Q.reject 'Cant save exists document'

    if @_parent
      return Q.reject 'Cant save embedded document'

    applyDefaultValues @

    @validate().then =>
      modelOf(@).execute('insert') (pickDocument @)
    .then ([document]) =>
      refreshDocument @, document
    .nodeify callback

  ###
  Public: To Object

  ```coffee
  document.toObject()
  ```

  return {Object}

  ###
  toObject: ->
    return toObject @

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

  TODO: embedded

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

  TODO: embedded

  ###
  remove: (callback) ->
    @_isRemoved = true
    modelOf(@).execute('remove')(_id: @_id).nodeify callback

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

  transform: ->
    transformDocument @

# Public: Mabolo
module.exports = class Mabolo
  connected: Q.defer()
  models: {}

  # Public: ObjectID from node-mongodb-native
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
  * `callback` (optional) {Function} `(err, db) ->`

  return {Promise} `(db) ->`
  ###
  connect: (uri, callback) ->
    MongoClient.connect uri, (err, db) =>
      if err
        @connected.reject err
      else
        @connected.resolve db

    @connected.promise.nodeify callback

  ###
  Public: Create a Mabolo Model

  * `name` {String} a camelcase model name, like `Account`
  * `schema` {Object}

    * `type` {String}, {Number}, {Date}, {Boolean} or {Mabolo::ObjectID}
    * `default` (optional) A value or a {Function}
    * `enum` (optional) {Array} of values
    * `regex` (optional) {RegExp}
    * `required` (optional) {Boolean}
    * `validator` (optional) {Function} or {Array}

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
        if /^[a-z]{3,8}$/.test username
          return null
        else
          return 'invalid_username'
  ```

  `validator` can be:

  * {Function} `(value, document) ->` throw a err (Sync) or return {Promise} (Async)
  * {Array} of {Function}

  ###
  model: (name, schema, options) ->
    options = _.extend(
      collection_name: lingo.pluralize name.toLowerCase()
      strict_pick: true
    , options)

    class model extends Model

    model.initialize
      _name: name
      _mabolo: @
      _schema: schema
      _options: options

      collection: @connected.promise.then (db) ->
        return db.collection options.collection_name

    @models[name] = model

    return model

# Helpers

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

splitArguments = (args) ->
  return {
    args: _.reject args, _.isFunction
    callback: _.find args, _.isFunction
  }

randomVersion = ->
  return crypto.pseudoRandomBytes(4).toString 'hex'

applyDefaultValues = (document) ->
  for path, {default: default_definition} of schemaOf(document)
    if dotGet(document, path) == undefined
      unless default_definition == undefined
        if _.isFunction default_definition
          dotSet document, path, default_definition(document)
        else
          dotSet document, path, default_definition

pickDocument = (document) ->
  if document.constructor._options.strict_pick
    result = dotPick document _.keys schemaOf document
  else
    result = _.pick.apply null, [document].concat _.keys document

  return _.extend result,
    __v: document.__v

refreshDocument = (document, latest) ->
  for path of schemaOf(document)
    dotSet document, path, dotGet(latest)

validatePath = (document, path) ->
  deferred = Q.defer()
  promises = []

  definition = dotGet document.constructor._schema, path
  value = dotGet document, path

  error = (message) ->
    deferred.reject new Error "Validating fail on `#{path}` #{message}"
    return deferred.promise

  # null or undefined
  if value in [null, undefined] and !definition.required
    return deferred.resolve()

  # embedded array
  if _.isArray definition
    Type = _.first definition

    if _.isArray value
      for item in value
        if isInstanceOf Type, item
          if isDocument item
            promises.push item.validate()
        else
          return error 'is Array of ' + typeNameOf Type

    else
      return error 'is Array'

  if definition.type
    Type = definition.type
  else if _.isFunction definition
    Type = definition
  else
    Type = null

  # type
  if Type
    if isInstanceOf Type, value
      if isEmbeddedDocumentPath value
        promises.push value.validate()
    else
      return error 'is ' + typeNameOf Type

  # enum
  if definition.enum
    unless value in definition.enum
      return error "in [#{definition.enum.join ', '}]"

  # regex
  if definition.regex
    unless definition.regex.test value
      return error 'match ' + definition.regex

  # validator
  if definition.validator
    if _.isArray definition.validator
      validators = definition.validator
    else
      validators = [definition.validator]

    for validator in validators
      try
        result = validator.call document, document
      catch err
        promises.push Q.reject err

      if Q.isPromise result
        promises.push result

  Q.all(promises).then deferred.resolve

  return deferred.promise

modelOf = (value) ->
  if value?._schema
    return value
  else
    return value?.constructor

schemaOf = (value) ->
  return modelOf(value)?._schema

typeOfDefinition = (definition) ->
  if definition.type
    return definition.type
  else if _.isFunction definition
    return definition
  else
    return null

typeNameOf = (value) ->
  return value?._name ? value?.name

isModel = (value) ->
  return value?._schema

isDocument = (value) ->
  return isModel value?.constructor

isEmbeddedDocument = (value) ->
  return value?._path and !value._index

isEmbeddedArray = (value) ->
  return value?._path and value._index

isInstanceOf = (Type, value) ->
  switch Type
    when String
      return _.isString value

    when Number
      return _.isNumber value

    when Date
      return _.isDate value

    when Boolean
      return _.isBoolean value

    else
      return value instanceof Type

toObject = (document) ->
  result = pickDocument document

  for path, definition of schemaOf(document)
    value = dotGet document, path

    # embedded array
    if _.isArray definition
      dotSet result, path, value.map (value) ->
        if isDocument value
          return value.toObject()
        else
          return value

    # embedded model
    else if isModel typeOfDefinition(definition)
      if isDocument value
        dotSet result, path, value.toObject()

  return result

transformDocument = (document) ->
  for path, definition of schemaOf(document)
    value = dotGet document, path

    # embedded array
    if _.isArray definition
      Type = _.first definition

      if value in [undefined, null]
        dotSet document, path, []

      else if isModel Type
        dotSet document, path, value.map (value, index) =>
          if isInstanceOf Type, value
            transformDocument value
            return value

          else
            return new Type _.extend value,
              _parent: @
              _path: path
              _index: index

    # embedded model
    else
      Type = typeOfDefinition definition

      if value in [undefined, null]
        continue

      if isModel Type
        if isInstanceOf Type, value
          transformDocument value

        else
          dotSet document, path, new Type _.extend value,
            _parent: @
            _path: path

addVersionForUpdates = (updates) ->
  is_atom_op = _.every _.keys(updates), (key) ->
    return key[0] == '$'

  if is_atom_op
    updates.$set ?= {}
    updates.$set['__v'] ?= randomVersion()
  else
    updates['__v'] ?= randomVersion()

addPrefixForUpdates = (document, updates) ->
  result = {}

  if document._index
    prefix = "#{document._path}.$."
  else
    prefix = "#{document._path}."

  for path, query of updates
    if path[0] == '$'
      if _.isObject(query) and !_.isArray(query)
        result[path] = addPrefixForUpdates document, query
    else
      result[prefix + path] = query

  return result
