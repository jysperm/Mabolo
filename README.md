## Mabolo
Just a simple wrapper of mongodb api.

> 这个东西还是非常好的嘛！—— Master Yeechan  
> 和 Mongoose 各有千秋。—— orzFly

![Travis-CI](https://img.shields.io/travis/jysperm/Mabolo.svg?style=flat-square)
![NPM Version](https://img.shields.io/npm/v/mabolo.svg?style=flat-square)
![NPM Downloads](https://img.shields.io/npm/dm/mabolo.svg?style=flat-square)

### Basic usages

Connect to MongoDB:

    Mabolo = require 'mabolo'
    mabolo = new Mabolo 'mongodb://localhost/test'

Create Model:

    User = mabolo.model 'User',
      username: String

Define model methods and instance methods:

    User.findByName = (name) ->
      arguments[0] = username: name
      @findOne.apply @, arguments

    User::getName = ->
      return @username

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

Find documents from MongoDB:

    User.find (err, users) ->
      console.log users[0].username

`User.find` will callback with array of data, instead of a Cursor.

Modify exists document atomically:

    user.modify (commit) ->
      @name = 'jysperm'
      commit()
    , (err) ->

The document will rollback to latest version if validating fail or `commit` received an err.

Default value for field:

    User = mabolo.model 'User',
      full_name:
        default: 'none'

Multi-level path:

    User = mabolo.model 'User',
      'name.full':
        default: 'none'

Define built-in validator for field

    User = mabolo.model 'User',
      username:
        type: String
        enum: ['tomato', 'potato']
        regex: /^[a-z]{3,8}$/
        required: true

Define your own validator:

    User = mabolo.model 'User',
      username:
        validator: (username) ->
          return /^[a-z]{3,8}$/.test username

Or asynchronous validator:

    User = mabolo.model 'User',
      username:
        validator: fs.exists

Multi-validator:

    User = mabolo.model 'User',
      username:
        validator:
          character: (username) -> /^[a-z]+$/.test username
          length: (username) -> 3 < username.length < 8

`character` and `length` will be included in error message.

### Embedded Document

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
* `String`, `Number`, `Date`, `ObjectID` also can be used as an embedded Model

You can use `parent()` to get parent document:

    Token::revoke = (callback) ->
      @parent().update
        $pull:
          tokens:
            code: @code
      , callback

Following methods is also available in embedded document:

* update
* modify
* remove

### Built-in methods

Mabolo Methods:

* constructor

        new Mabolo()
        new Mabolo 'mongodb://localhost/test'

* connect

        mabolo.connect uri, [callback]

    * callback: `(err, db)` ->

* model

        mabolo.model name, schema, [options]

    * name: a camelcase model name, like `Account`
    * schema:

        * type: `String`, `Number`, `Date`, `Boolean`, `mabolo.ObjectID`
        * default: value or `Function`
        * enum: `Array` of values
        * regex: `RegExp`
        * required: `true` or `false`
        * validator:

            * function: `->`
            * array of function: `[->, ->]`
            * object of function: `{a: ->, b: ->}`

            function:

            * synchronous, return err if fail: `(value) ->`
            * asynchronous, callback err if fail: `(value, callback) ->`

    * options:

        * collection_name: overwrite default collection name
        * strict_pick: only store defined fields to database, default `true`

Model Methods:

* getCollection

        Model.getCollection()

    * return: `Collection` of `node-mongodb-native`

* transform

        Model.transform document
        Model.transform documents

    * return: `document` or `documents`

* create

        Model.create document, callback

    * document: `object`
    * callback: `(err, document) ->`
    * callback@: `document`

* ensureIndex

        Model.ensureIndex fields, [options], callback

* aggregate

        Model.aggregate commands, [options], callback

* count

        Model.count query, [options], callback
        Model.count callback

    * callback: `(err, count) ->`
    * callback@: `Model`

* find

        Model.find query, [options], callback
        Model.find callback

    * callback: `(err, documents) ->`
    * callback@: `Model`

* findOne

        Model.findOne query, [options], callback
        Model.find callback

    * callback: `(err, document) ->`
    * callback@: `Model`

* findById

        Model.findById id, [options], callback

    * callback: `(err, document) ->`
    * callback@: `Model`

* findOneAndUpdate

        Model.findOneAndUpdate query, updates, [options], callback

    * options.sort: `{field: -1}`
    * options.new: default `true`
    * callback: `(err, document) ->`
    * callback@: `Model`

* findByIdAndUpdate

        Model.findByIdAndUpdate id, updates, [options], callback

    * options.new: default `true`
    * callback: `(err, document) ->`
    * callback@: `Model`

* findOneAndRemove

        Model.findOneAndRemove query, [options], callback

    * options.sort: `{field: -1}`
    * callback: `(err, document) ->`
    * callback@: `Model`

* findByIdAndRemove

        Model.findByIdAndRemove id, [options], callback

    * callback: `(err, document) ->`
    * callback@: `Model`

* update

        Model.update query, updates, [options], callback

    * callback: `(err, result) ->`
    * callback@: `Model`

* remove

        Model.remove query, [options], callback

    * callback: `(err, result) ->`
    * callback@: `Model`

Instance Methods:

* constructor

        new Model document

* transformSubDocuments

        document.transformSubDocuments()

* parent

        document.parent()

    * return: parent `document`

* toObject

        document.toObject()

    * return: `object`

* update

        document.update updates, [options], callback
        document.embedded.update updates, [options], callback

    * options.new: default `true`
    * callback: `(err) ->`
    * callback@: `document`

* save

        document.save callback

    * callback: `(err) ->`
    * callback@: `document`

* validate

        document.validate callback
        document.embedded.validate callback

    * callback: `(err) ->`
    * callback@: `document`

* remove

        document.remove callback
        document.embedded.remove callback

    * callback: `(err, result) ->`

### Todo list

* Type casts automatically
* Prevent injection
* Benchmark tests
* Reference relationship between models
