mabolo = new Mabolo mongodb_uri

describe 'model.validate', ->
  describe 'type, required', ->
    User = null

    before ->
      User = mabolo.model 'User',
        username:
          required: true
          type: String

        age:
          required: true
          type: Number

        birthday:
          type: Date

        id:
          type: mabolo.ObjectID

        bool:
          type: Boolean

        anything:
          type: Object

        'sub.path':
          type: String

    it 'should success', (done) ->
      jysperm = new User
        username: 'jysperm'
        age: 19
        birthday: new Date '1995-11-25'
        id: mabolo.ObjectID()
        bool: false
        sub:
          path: 'string'

      jysperm.validate done

    it 'should success with part of paths', (done) ->
      jysperm = new User
        username: 'jysperm'
        age: 19

      jysperm.validate done

    it 'should fail when invalid date', (done) ->
      jysperm = new User
        username: 'jysperm'
        age: 19
        birthday: '1995-11-25'

      jysperm.validate (err) ->
        err.message.should.match /birthday.*is Date/
        done()

    it 'should fail when path not exist', (done) ->
      jysperm = new User
        username: 'jysperm'

      jysperm.validate (err) ->
        err.message.should.match /age.*is Number/
        done()

  describe 'enum, regex', ->
    User = null

    before ->
      User = mabolo.model 'User',
        username:
          required: true
          regex: /^[a-z]{3,8}$/

        age:
          type: Number
          enum: [18, 19]

    it 'should success', (done) ->
      jysperm = new User
        username: 'jysperm'
        age: 19

      jysperm.validate done

    it 'should success when no value', (done) ->
      jysperm = new User
        username: 'jysperm'

      jysperm.validate done

    it 'should fail with regex', (done) ->
      jysperm = new User
        username: 'JYSPERM'

      jysperm.validate (err) ->
        err.message.should.match /username.*match/
        done()

    it 'should fail with enum', (done) ->
      jysperm = new User
        username: 'jysperm'
        age: 20

      jysperm.validate (err) ->
        err.message.should.match /age.*in/
        done()

  describe 'sync validator', ->
    User = null

    before ->
      User = mabolo.model 'User',
        username:
          validator: (username) ->
            return /^[a-z]{3,8}$/.test username

        nickname:
          validator:
            character: (nickname) -> /^[a-z]+$/.test nickname
            length: (nickname) -> 3 < nickname.length < 8

    it 'should success', (done) ->
      jysperm = new User
        username: 'jysperm'
        nickname: 'jysperm'

      jysperm.validate done

    it 'should fail with username', (done) ->
      jysperm = new User
        username: 'JYSPERM'

      jysperm.validate (err) ->
        err.message.should.match /username.*validator/
        done()

    it 'should fail with character', (done) ->
      jysperm = new User
        nickname: 'JYSPERM'

      jysperm.validate (err) ->
        err.message.should.match /nickname.*character/
        done()

    it 'should fail with length', (done) ->
      jysperm = new User
        nickname: 'jy'

      jysperm.validate (err) ->
        err.message.should.match /nickname.*length/
        done()

  describe 'async validator', ->
    User = null

    before ->
      User = mabolo.model 'User',
        username:
          validator: (require 'fs').exists

    it 'should success', (done) ->
      jysperm = new User
       username: 'jysperm'

      jysperm.validate done

    it 'should fail', (done) ->
      jysperm = new User
        username: 'index.coffee'

      jysperm.validate (err) ->
        err.message.should.match /username/
        done()
