## Mabolo
Just a simple wrapper of mongodb api.

### Connect to MongoDB

    Mabolo = require 'mabolo'
    mabolo = new Mabolo 'mongodb://localhost/test'

### Create Model

    User = mabolo.model 'User',
      username:
        type: String

Define model methods and instance methods:

    User.findByName = (name) ->
      arguments[0] = username: name
      @findOne.apply @, arguments

    User::getName = ->
      return @username

### Build-in methods

Model Methods:

* Model.create
* Model.count
* Model.find
* Model.findOne
* Model.findById
* Model.findOneAndUpdate
* Model.findByIdAndUpdate
* Model.findOneAndRemove
* Model.findByIdAndRemove
* Model.update
* Model.remove
* Model.getCollection
* Model.buildDocument

Instance Methods:

* document.toObject
* document.update
* document.save
* document.remove
* (TODO) document.validate

### Create user and save to MongoDB
Mabolo will queue your operators before connected to MongoDB.

    user = new User
      username: 'jysperm'

    user.save (err) ->
      console.log @_id

Or use `User.create`:

    User.create
      username: 'jysperm'
    , (err, user) ->
      console.log user._id

### Find users from MongoDB
`User.find` will callback with array of data, instead of a Cursor.

    User.find {}, (err, users) ->
      console.log users[0].username

### TODO list

* `document.save` support save exists document
* Use schema definition to validate document
* Support embedded and reference relationship between models
