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

      jysperm.validate (err) ->
        done err

    it 'should success with part of paths', (done) ->
      jysperm = new User
        username: 'jysperm'
        age: 19

      jysperm.validate (err) ->
        done err

    it 'should fail when invalid date', (done) ->
      jysperm = new User
        username: 'jysperm'
        age: 19
        birthday: '1995-11-25'

      jysperm.validate (err) ->
        err.message.should.match /birthday.*is date/
        done()

    it 'should fail when path not exist', (done) ->
      jysperm = new User
        username: 'jysperm'

      jysperm.validate (err) ->
        err.message.should.match /age.*is number/
        done()
