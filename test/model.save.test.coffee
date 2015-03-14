mabolo = new Mabolo mongodb_uri

describe.skip 'model.save', ->
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
