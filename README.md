## Mabolo
Just a simple wrapper of mongodb api.

> 这个东西还是非常好的嘛！—— Master Yeechan  
> 和 Mongoose 各有千秋。—— orzFly

### Basic usages

Connect to MongoDB:

    Mabolo = require 'mabolo'
    mabolo = new Mabolo 'mongodb://localhost/test'

Create Model:

    User = mabolo.model 'User',
      username:
        type: String

Define model methods and instance methods:

    User.findByName = (name) ->
      arguments[0] = username: name
      @findOne.apply @, arguments

    User::getName = ->
      return @username

Create user and save to MongoDB:

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

Find users from MongoDB:

    User.find {}, (err, users) ->
      console.log users[0].username

`User.find` will callback with array of data, instead of a Cursor.

Modify exists document atomically:

    user.modify (commit) ->
      @name = 'jysperm'
      commit()
    , (err) ->
      # ...

The document will rollback to latest version if validating fail or `commit` received an err.

### Built-in methods

Model Methods:

* getCollection

        Model.getCollection()

    * return: `Collection` of `node-mongodb-native`

* transform

        Model.transform document
        Model.transform documents

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

* document.toObject
* document.update
* document.save
* document.modify
* document.remove
* document.validate

### Default value for field

    User = mabolo.model 'User',
      full_name:
        default: 'none'

* default: default value of this field

Multi-level path:

    User = mabolo.model 'User',
      'name.full':
        default: 'none'

### Define Validator for field

Built-in validator:

    User = mabolo.model 'User',
      username:
        type: String
        enum: ['tomato', 'potato']
        regex: /^[a-z]{3,8}$/
        required: true

* type: `String`, `Number`, `Date`, `Boolean`, `mabolo.ObjectID`

    And `Object` meaning that no additional validation, same with `null`

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

### Embedded Model

    Token = mabolo.model 'Token',
      code:
        type: String

    User = mabolo.model 'User',
      username:
        type: String

      last_token:
        type: Token

      friends_id: [mabolo.ObjectID]
      tokens: [Token]
      tags: [String]

* Every sub-Model has a `_id` and `__v`
* Validators of sub-Model will be run first
* Sub-Model will be create when parent-Model created
* `String`, `Number`, `Date`, `Boolean`, `mabolo.ObjectID` also can be used as an sub-Model

You can use `parent()` to get instance of parent-Model:

    Token::revoke = (callback) ->
      @parent().update
        $pull:
          tokens:
            code: @code
      , callback

Only following methods is available in sub-Model instance:

* toObject
* update
* modify
* remove
* validate

### Todo list

* Validating a path of document only
* Support reference relationship between models
* Define database indexs
