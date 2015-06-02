{ObjectID, MongoClient} = require 'mongodb'
{EventEmitter} = require 'events'
inflection = require 'inflection'
crypto = require 'crypto'
_ = require 'underscore'
Q = require 'q'

###
Public: Mabolo Model

Define model methods and instance methods:

```coffee
User.findByName = (name, options...) ->
  return @findOne name: name, options...

User::getName = ->
  return @username
```

###
class Model
  ###
  Section: Create Document

  Create document and save to MongoDB:

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
  Public: Constructor from a object

  * `document` {Object}

  Every document will be added a `__v` automatically, it is a random version to prevent conflict when {Model::modify}.

  ###
  constructor: (document) ->
    Object.defineProperties @,
      # Does the document saved to MongoDB
      _isNew:
        writable: true
      # Does the document removed from MongoDB
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
  Public: Create document and save

  * `document` {Object}
  * `callback` (optional) {Function}

  return {Promise} resolve with document.

  ###
  @create: (document, callback) ->
    document = new @ document

    return document.save().then ->
      return document
    .nodeify callback

  ###
  Section: Query Documents

  Find documents from MongoDB:

  ```coffee
  User.find (err, users) ->
    console.log users[0].username
  ```

  ###

  ###
  Public: Find

  * `query` (optional) {Object}
  * `options` (optional) {Object}
  * `callback` (optional) {Function}

  return {Promise} resolve with documents. {Model.find} will return array of data, instead of a Cursor.

  ###
  @find: ->
    {args, callback} = splitArguments arguments

    return @execute('find')(args...).then (cursor) =>
      return Q.Promise (resolve, reject) =>
        cursor.toArray (err, documents) =>
          if err
            reject err
          else
            resolve @transform documents
    .nodeify callback

  ###
  Public: Find one

  * `query` (optional) {Object}
  * `options` (optional) {Object}
  * `callback` (optional) {Function}

  return {Promise} resolve with document.

  ###
  @findOne: ->
    {args, callback} = splitArguments arguments
    return @execute('findOne')(args...).nodeify callback

  ###
  Public: Find by id

  * `id` {Mabolo::ObjectID} or {String}
  * `options` (optional) {Object}
  * `callback` (optional) {Function}

  return {Promise} resolve with document.

  ###
  @findById: ->
    {args: [id, args...], callback} = splitArguments arguments
    return Q.Promise (resolve, reject) =>
      @findOne(_id: ObjectID id, args...).then resolve, reject
    .nodeify callback

  ###
  Public: Count

  * `query` (optional) {Object}
  * `callback` (optional) {Function}

  return {Promise} resolve with a {Number} of count.

  ###
  @count: ->
    {args, callback} = splitArguments arguments
    return @execute('count')(args...).nodeify callback

  ###
  Public: Aggregate

  * `commands` {Array}
  * `options` (optional) {Object}
  * `callback` (optional) {Function}

  return {Promise} resolve with result from MongoDB.

  ###
  @aggregate: ->
    {args, callback} = splitArguments arguments
    return @execute('aggregate')(args...).nodeify callback

  ###
  Section: Manage Collection
  ###

  ###
  Public: Get collection

  return {Promise} resolve with `Collection` from node-mongodb-native

  ###
  @collection: ->

  ###
  Public: Ensure index

  * `fileds` {Object}
  * `options` (optional) {Object}
  * `callback` (optional) {Function}

  return {Promise} resolve with result from MongoDB.

  ###
  @ensureIndex: ->
    {args, callback} = splitArguments arguments
    return @execute('ensureIndex')(args...).nodeify callback

  ###
  Section: Update Documents
  ###

  ###
  Public: Update

  * `query` {Object}
  * `updates` {Object}
  * `options` (optional) {Object}
  * `callback` (optional) {Function}

  return {Promise} resolve with result from MongoDB.

  ###
  @update: (query, updates) ->
    addVersionForUpdates updates
    {args, callback} = splitArguments arguments
    return @execute('update')(args...).nodeify callback

  ###
  Public: Remove

  ```coffee
  Model.remove query, [options], [callback]
  ```

  * `query` {Object}
  * `options` (optional) {Object}
  * `callback` (optional) {Function}

  return a {Promise}.

  ###
  @remove: ->
    {args, callback} = splitArguments arguments
    return @execute('remove')(args...).nodeify callback

  ###
  Public: Fine one and update

  * `query` {Object}
  * `updates` {Object}
  * `options` (optional) {Object}

    * `sort` (optional) {Object} like `{field: -1}`
    * `new` (optional) {Boolean} default `true`

  * `callback` (optional) {Function}

  return {Promise} resolve with document if `options.new` is `true`

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

  * `id` {ObjectID}
  * `updates` {Object}
  * `options` (optional) {Object}

    * `new` (optional) {Boolean} default `true`

  * `callback` (optional) {Function}

  return {Promise} resolve with document if `options.new` is `true`

  ###
  @findByIdAndUpdate: ->
    {args: [id, args...], callback} = splitArguments arguments

    return Q.Promise (resolve, reject) =>
      return @findOneAndUpdate(_id: ObjectID(id), args...).then resolve, reject
    .nodeify callback

  ###
  Public: Find one and remove

  * `query` {Object}
  * `options` (optional) {Object}

    * `sort` (optional) {Object} like `{field: -1}`

  * `callback` (optional) {Function}

  return {Promise} resolve with result from MongoDB.

  ###
  @findOneAndRemove: ->
    {args: [query, options], callback} = splitArguments arguments

    options ?=
      sort: null

    return @execute('findAndRemove')(query, options.sort, options).nodeify callback

  ###
  Public: Find by id and remove

  * `id` {ObjectID}
  * `options` (optional) {Object}
  * `callback` (optional) {Function}

  return {Promise} resolve with result from MongoDB.

  ###
  @findByIdAndRemove: ->
    {args: [id, args...], callback} = splitArguments arguments

    return Q.Promise (resolve, reject) =>
      return @findOneAndRemove(_id: ObjectID(id), args...).then resolve, reject
    .nodeify callback

  @initialize: (options) ->
    _.extend @, options,
      collectionDeferred: Q.defer()

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

  @bindCollection: (collection) ->
    @collectionDeferred.resolve collection

  @collection: ->
    return @collectionDeferred.promise

  @execute: (name) ->
    return =>
      args = arguments
      model = @

      model.collection().then (collection) ->
        return Q.Promise (resolve, reject) ->
          collection[name] args..., (err, result) ->
            if err
              reject err
            else
              resolve model.transform result

  ###
  Section: Document Methods
  ###

  ###
  Public: Validate document

  * `callback` (optional) {Function}

  return a {Promise}.

  ###
  validate: (callback) ->
    @transform()

    Q().then =>
      if containsOperators @
        throw new Error 'Document contains MongoDB operators'

      Q.all _.keys(schemaOf @).map (path) =>
        return validatePath @, path
    .nodeify callback

  ###
  Public: Validate single path

  * `path` {String}
  * `callback` (optional) {Function}

  return a {Promise}.

  ###
  validatePath: (path, callback) ->
    transformPath @, path
    return validatePath(@, path).nodeify callback

  ###
  Public: Save

  * `callback` (optional) {Function}

  return a {Promise}.

  ###
  save: (callback) ->
    if !@_isNew and @_isRemoved
      return Q.reject 'Cant save exists document'

    if @_parent
      return Q.reject 'Cant save embedded document'

    applyDefaultValues @

    @validate().then =>
      modelOf(@).execute('insert') pickDocument(@, '__v')
    .then ([document]) =>
      refreshDocument @, document
      document._isNew = false
      document._isRemoved = false
      return document
    .nodeify callback

  ###
  Public: To object

  return a {Object}.

  ###
  toObject: ->
    return toObject @

  ###
  Public: Transform

  Construct all embedded document.

  ###

  transform: ->
    for path of schemaOf(@)
      transformPath @, path

  ###
  Public: Update

  * `updates` {Object}
  * `options` {optional} {Object}
  * `callback` (optional) {Function}

  return {Promise} resolve with new document.

  TODO: embedded

  ###
  update: ->
    {args, callback} = splitArguments arguments

    return modelOf(@).findByIdAndUpdate(@_id, args...).then (document) =>
      if isDocument document
        refreshDocument @, document
      return document
    .nodeify callback

  ###
  Public: Modify document atomically

  * `modifier` {Function} `(document) ->`
  * `callback` (optional) {Function}

  return {Promise} resolve with new document or reject with err.

  * If `modifier` executed without exception or return a resolved Promise, changes to document will be commit.
  * If `modifier` return a rejected Promise or throw a exception, changes to document will be rollback.
  * If validating fail, document will be rollback too.

  TODO: embedded

  ## Examples

  Modify exists document atomically:

  ```coffee
  jysperm.modify (jysperm) ->
    Q.delay(1000).then ->
      jysperm.age = 19
  .then ->
  ```

  ###
  modify: (modifier, callback) ->
    id = @_id
    model = modelOf @

    unless id
      throw new Error 'Document not yet exists in MongoDB'

    commit = (document) ->
      version = document.__v

      Q().then ->
        return modifier.call document, document
      .then ->
        return document.validate()
      .then ->
        model.findOneAndUpdate(
          _id: id
          __v: version
        , _.extend(document,
          __v: randomVersion()
        )).then (result) ->
          if result
            return result
          else
            model.findById(id).then commit

    commit(@).then (document) =>
      refreshDocument @, document
    .catch (err) =>
      model.findById(id).then (latest) =>
        refreshDocument @, latest
    .nodeify callback

  ###
  Public: Remove

  * `callback` (optional) {Function}

  return a {Promise}.

  TODO: embedded

  ###
  remove: (callback) ->
    @_isRemoved = true
    modelOf(@).execute('remove')(_id: @_id).nodeify callback

  ###
  Section: Embedded Document

  ```coffee
  Token = mabolo.model 'Token',
    code: String

  User = mabolo.model 'User',
    username: String
    last_token: Token
    tokens: [Token]
    tags: [String]
  ```

  * Every embedded document has a `_id` and `__v`
  * Validators of embedded document will be run after parent document
  * Embedded document will be create when parent document created
  * `String`, `Number`, `Date`, `ObjectID` also can be used as an Model

  You can use `parent()` to get parent document:

  ```coffee
  Token::revoke = (callback) ->
    @parent().update
      $pull:
        tokens:
          code: @code
    , callback
  ```

  ###

  ###
  Public: Parent document

  return parent document.

  ###
  parent: ->
    return @_parent

# Public: Mabolo
module.exports = class Mabolo
  # Public: ObjectID of node-mongodb-native
  ObjectID: ObjectID

  ###
  Public: Create a Mabolo Model

  * `name` {String} a camelcase model name, like `Account`
  * `schema` {Object}, key should be field path, value should be a {Object}:

    * `type` {String}, {Number}, {Date}, {Boolean} or {Mabolo::ObjectID}
    * `validator` (optional) {Function} or {Array}:

      * `(value) ->` throw a err (Sync) or return {Promise} (Async)
      * {Array} of {Function}

    * `required` (optional) {Boolean}
    * `default` (optional) A value or a {Function}
    * `regex` (optional) {RegExp}
    * `enum` (optional) {Array} of values

  * `options` (optional) {Object}

    * `collection` {String} overwrite default collection name
    * `strictPick` {Boolean} only store defined fields to database, default `true`

  return a Class extends from {Model}

  ## Examples

  if schema field has only a type, it can shorthand like:

  ```coffee
  User = Mabolo.model 'User',
    username: String
    age: Number
  ```

  Use dot to split Multi-level path:

  ```coffee
  User = Mabolo.model 'User',
    'name.full':
      default: 'none'
  ```

  Define built-in validator for field:

  ```coffee
  User = Mabolo.model 'User',
    username:
      type: String
      required: true
      enum: ['tomato', 'potato']
  ```

  Define your own validator:

  ```coffee
  User = Mabolo.model 'User',
    username:
      validator: (username) ->
        unless /^[a-z]{3,8}$/.test username
          throw new Error 'invalid_username'
  ```

  ###
  @model: (name, schema, options = {}) ->
    _.defaults options,
      collection: inflection.pluralize name.toLowerCase()
      strictPick: true

    class ModelInstance extends Model

    ModelInstance.initialize
      _name: name
      _schema: formatSchema schema
      _options: options

    return ModelInstance

  ###
  Public: Create a new Mabolo instance

  * `uri` (optional) {String} uri of MongoDB

  ###
  constructor: (uri) ->
    if uri
      @connect uri

  ###
  Public: Connect to MongoDB

  * `uri` {String} uri of MongoDB, like `mongodb://localhost/test`
  * `callback` (optional) {Function}

  return {Promise} resolve with `Db` of node-mongodb-native

  ###
  connect: (uri, callback) ->
    if @connected
      return @connected.promise.nodeify(uri ? callback)
    else
      @connected = Q.defer()

    MongoClient.connect uri, @connected.makeNodeResolver()

    return @connected.promise.nodeify callback

  ###
    Public: Create a Mabolo Model

    Same with {Mabolo.model}, But does not require call {Mabolo::bind}.
  ###
  model: (name, schema, options) ->
    return @bind Mabolo.model arguments...

  ###
    Public: Bind a Model to this mabolo instance.

    * `ModelInstance` {Model}

    Return {Model}.
  ###
  bind: (ModelInstance) ->
    @connect().then (db) ->
      ModelInstance.bindCollection db.collection optionsOf(ModelInstance).collection

    return ModelInstance

# Helpers

Mabolo.ObjectID = ObjectID
Mabolo.helpers = helpers = {}

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

pickDocument = (document, keys...) ->
  if optionsOf(document).strictPick
    result = dotPick document, _.keys schemaOf document
  else
    result = _.pick document, (_.keys document)...

  return _.extend result, _.pick(document, keys...)

refreshDocument = (document, latest) ->
  unless optionsOf(document).strictPick
    _.extend document, latest

  for path, spec of schemaOf(document)
    if isModel spec.type
      refreshDocument dotGet(document, path), dotGet(latest, path)

    else
      dotSet document, path, dotGet(latest, path)

  for field in ['_id', '__v']
    document[field] = latest[field] if latest[field]

  return document

formatSchema = (schema) ->
  for path, definition of schema
    if _.isFunction definition
      schema[path] =
        type: definition

    if definition.validator
      if _.isArray definition.validator
        definition.validators = definition.validator
      else
        definition.validators = [definition.validator]

  return schema

validatePath = (document, path) ->
  deferred = Q.defer()
  promises = []

  definition = schemaOf(document)[path]
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

  # type
  if definition.type
    if isInstanceOf definition.type, value
      if isEmbeddedDocument value
        promises.push value.validate()
    else
      return error 'is ' + typeNameOf definition.type

  # enum
  if definition.enum
    unless value in definition.enum
      return error "in [#{definition.enum.join ', '}]"

  # regex
  if definition.regex
    unless definition.regex.test value
      return error 'match ' + definition.regex

  # validator
  unless _.isEmpty definition.validators
    for validator in definition.validators
      try
        result = validator.call document, value
      catch err
        promises.push Q.reject err

      if Q.isPromise result
        promises.push result

  Q.all(promises).then deferred.resolve, deferred.reject

  return deferred.promise

modelOf = (value) ->
  if value?._schema
    return value
  else
    return value?.constructor

schemaOf = (value) ->
  return modelOf(value)?._schema

optionsOf = (value) ->
  return modelOf(value)?._options

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
    else if isModel definition.type
      if isDocument value
        dotSet result, path, value.toObject()

  return result

transformPath = (document, path) ->
  definition = schemaOf(document)[path]
  value = dotGet document, path

  # embedded array
  if _.isArray definition
    Type = _.first definition

    if value in [undefined, null]
      dotSet document, path, []

    else if isModel Type
      dotSet document, path, value.map (value, index) ->
        if isInstanceOf Type, value
          value.transform()

          unless value._id
            value._id = ObjectID()

          return value

        else
          return new Type _.extend value,
            _parent: document
            _path: path
            _index: index

  # embedded model
  else
    Type = definition.type

    if value in [undefined, null]
      return

    if isModel Type
      if isInstanceOf Type, value
        value.transform()

        unless value._parent
          _.extend value,
            _parent: document
            _path: path

        unless value._id
          value._id = ObjectID()

      else
        dotSet document, path, new Type _.extend value,
          _parent: document
          _path: path

addVersionForUpdates = (updates) ->
  is_atom_op = _.every _.keys(updates), (key) ->
    return key[0] == '$'

  if is_atom_op
    updates.$set ?= {}
    updates.$set['__v'] ?= randomVersion()
  else
    updates['__v'] ?= randomVersion()

addPrefixForUpdates = helpers.addPrefixForUpdates = (document, updates) ->
  result = {}

  if document._index
    prefix = "#{document._path}.$."
  else if document._path
    prefix = "#{document._path}."
  else
    return updates

  for path, query of updates
    if path[0] == '$'
      if _.isObject(query) and !_.isArray(query)
        result[path] = addPrefixForUpdates document, query
    else
      result[prefix + path] = query

  return result

containsOperators = helpers.containsOperators = (document) ->
  for key, value of document
    if '$' in key
      return true
    else if _.isObject value
      return containsOperators value
    else if _.isArray value
      return value.some (item) ->
        if _.isObject item
          return containsOperators item
        else
          return false

  return false
