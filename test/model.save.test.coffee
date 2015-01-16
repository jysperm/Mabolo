mabolo = new Mabolo mongodb_uri

User = mabolo.model 'User',
  username:
    required: true
    type: String

  age:
    required: true
    type: Number
    default: 18

describe 'model.save', ->
  describe 'default value', ->
    it 'Model.create', (done) ->
      User.create
        username: 'jysperm'
      , (err, jysperm) ->
        jysperm.age.should.be.equal 18
        done err

    it 'constructor', (done) ->
      jysperm = new User
        username: 'jysperm'

      jysperm.save (err) ->
        jysperm.age.should.be.equal 18
        done err
