describe 'Mabolo', ->
  describe '#connect', ->
    it 'constructor with uri', (done) ->
      mabolo = new Mabolo mongodb_uri
      mabolo.connect().nodeify done

    it 'constructor without uri (callback style)', (done) ->
      mabolo = new Mabolo()
      mabolo.connect mongodb_uri, (err, db) ->
        db.should.be.exist
        done err

    it 'constructor without uri (promise style)', (done) ->
      mabolo = new Mabolo()
      mabolo.connect(mongodb_uri).nodeify done

  describe '#model', ->
    mabolo = new Mabolo mongodb_uri
    User = null

    it 'basic usage', ->
      User = mabolo.model 'User',
        username:
          type: String
          required: true
          validator: (username) ->
            unless /^[a-z]{3,8}$/.test username
              throw new Error 'invalid_username'

        age: Number

        color:
          enum: ['red', 'green']

        'name.full':
          default: 'none'

      User.findByName = (name, options...) ->
        return @findOne name: name, options...

      User::getName = ->
        return @username

      User._schema.username.validators.should.instanceof Array
      User._schema.age.type.should.be.equal Number

      User.findByName.should.be.a 'function'
      (new User).getName.should.be.a 'Function'

    it 'options', ->
      Map = mabolo.model 'Map', {},
        collection_name: 'map'

      Map._options.collection_name.should.be.equal 'map'

  describe '#bind', ->
    it 'should success', ->
      mabolo = new Mabolo mongodb_uri

      User = Mabolo.model 'User',
        username: String

      mabolo.bind User

      return User.find()
