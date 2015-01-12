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

    User.staticMethod = ->

    User.methods.instanceMethod = ->

### Build-in methods

Model Methods:

* User.find
* User.findOne
* User.findById
* User.findByIdAndUpdate
* User.getCollection

Instance Methods:

* user.toObject
* user.update
* user.remove

### Create user and save to MongoDB
Mabolo will queue your operators before connected to MongoDB.

    User.create
      username: 'jysperm'
    , (err, user) ->
      console.log user._id

### find users from MongoDB
`User.find` will callback with array of data, instead of a Cursor.

    User.find {}, (err, users) ->
      console.log users[0].username
