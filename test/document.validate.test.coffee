describe 'document.validate', ->
  mabolo = new Mabolo mongodb_uri
  {ObjectID} = Mabolo

  describe 'type and required', ->
    User = mabolo.model 'User',
      name:
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
        name: 'jysperm'
        age: 19
        birthday: new Date '1995-11-25'
        id: ObjectID()
        girl: false
        sub:
          path: 'string'

      return jysperm.validate()

    it 'should success with required paths', ->
      jysperm = new User
        name: 'jysperm'
        age: 19

      return jysperm.validate()

    it 'should fail with invalid value', (done) ->
      jysperm = new User
        name: 'jysperm'
        age: 19
        birthday: 'invalid-date'

      jysperm.validate (err) ->
        err.message.should.match /birthday.*Date/
        done()

    it 'should fail with missing required path', (done) ->
      jysperm = new User
        name: 'jysperm'

      jysperm.validate (err) ->
        err.message.should.match /age.*Number/
        done()

  describe 'enum and regex', ->
    User = mabolo.model 'User',
      name:
        required: true
        regex: /^[a-z]{3,8}$/

      age:
        type: Number
        enum: [18, 19]
    ,
      memoize: false

    it 'should success', ->
      jysperm = new User
        name: 'jysperm'
        age: 19

      return jysperm.validate()

    it 'should success when ignore', ->
      jysperm = new User
        name: 'jysperm'

      return jysperm.validate()

    it 'should fail because regex', (done) ->
      jysperm = new User
        name: 'JYSPERM'

      jysperm.validate (err) ->
        err.message.should.match /name.*match/
        done()

    it 'should fail because enum', (done) ->
      jysperm = new User
        name: 'jysperm'
        age: 20

      jysperm.validate (err) ->
        err.message.should.match /age.*in/
        done()

  describe 'injection attacks', ->
    User = mabolo.model 'User',
      name: Object
    , memoize: false

    it 'should fail', (done) ->
      jysperm = new User
        name:
          $gt: 1

      jysperm.validate (err) ->
        err.message.should.match /contains.*operators/
        done()

  describe 'validator', ->
    User = mabolo.model 'User',
      name:
        validator: (name) ->
          unless /^[a-z]{3,8}$/.test name
            throw new Error 'invalid_name'
    ,
      memoize: false

    it 'should success', ->
      jysperm = new User
        name: 'jysperm'

      return jysperm.validate()

    it 'should fail', (done) ->
      jysperm = new User
        name: 'JYSPERM'

      jysperm.validate (err) ->
        err.message.should.match /invalid_name/
        done()

  describe '#validatePath', ->
    User = mabolo.model 'User',
      name:
        regex: /^[a-z]{3,8}$/
        type: String

      age:
        type: Number
        enum: [18, 19]
    ,
      memoize: false

    jysperm = new User
      name: 'JYSPERM'
      age: 19

    it 'should success', ->
      return jysperm.validatePath('age')

    it 'should fail', (done) ->
      jysperm.validatePath 'name', (err) ->
        err.message.should.match /name/
        done()
