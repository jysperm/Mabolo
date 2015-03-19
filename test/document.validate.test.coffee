describe 'document.validate', ->
  mabolo = new Mabolo mongodb_uri
  {ObjectID} = Mabolo

  describe 'type and required', ->
    User = mabolo.model 'User',
      username:
        required: true
        type: String

      age:
        required: true
        type: Number

      birthday: Date
      girl: Boolean
      id: ObjectID
      'sub.path': String
    ,
      memoize: false

    it 'should success', ->
      jysperm = new User
        username: 'jysperm'
        age: 19
        birthday: new Date '1995-11-25'
        id: ObjectID()
        girl: false
        sub:
          path: 'string'

      return jysperm.validate()

    it 'should success with required paths', ->
      jysperm = new User
        username: 'jysperm'
        age: 19

      return jysperm.validate()

    it 'should fail with invalid value', (done) ->
      jysperm = new User
        username: 'jysperm'
        age: 19
        birthday: 'invalid-date'

      jysperm.validate (err) ->
        err.message.should.match /birthday.*Date/
        done()

    it 'should fail with missing required path', (done) ->
      jysperm = new User
        username: 'jysperm'

      jysperm.validate (err) ->
        err.message.should.match /age.*Number/
        done()

  describe 'enum and regex', ->
    User = mabolo.model 'User',
      username:
        required: true
        regex: /^[a-z]{3,8}$/

      age:
        type: Number
        enum: [18, 19]
    ,
      memoize: false

    it 'should success', ->
      jysperm = new User
        username: 'jysperm'
        age: 19

      return jysperm.validate()

    it 'should success when ignore', ->
      jysperm = new User
        username: 'jysperm'

      return jysperm.validate()

    it 'should fail because regex', (done) ->
      jysperm = new User
        username: 'JYSPERM'

      jysperm.validate (err) ->
        err.message.should.match /username.*match/
        done()

    it 'should fail because enum', (done) ->
      jysperm = new User
        username: 'jysperm'
        age: 20

      jysperm.validate (err) ->
        err.message.should.match /age.*in/
        done()

  describe 'validator', ->
    User = mabolo.model 'User',
      username:
        validator: (username) ->
          unless /^[a-z]{3,8}$/.test username
            throw new Error 'invalid_username'
    ,
      memoize: false

    it 'should success', ->
      jysperm = new User
        username: 'jysperm'

      return jysperm.validate()

    it 'should fail', (done) ->
      jysperm = new User
        username: 'JYSPERM'

      jysperm.validate (err) ->
        err.message.should.match /invalid_username/
        done()
