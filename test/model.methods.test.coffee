mabolo = new Mabolo mongodb_uri

describe.skip 'model.methods', ->
  jysperm = null

  describe 'model.constructor', ->
    it 'create jysperm', (done) ->
      jysperm = new User
        username: 'jysperm'

      jysperm.toObject().should.be.eql
        username: 'jysperm'

  describe 'model.update', ->
    it 'update', (done) ->
      jysperm.update
        $set:
          email: 'jysperm@gmail.com'
      , (err) ->
        jysperm.email.should.be.equal 'jysperm@gmail.com'
        done err

  describe 'model.remove', (done) ->
    it 'remove', (done) ->
      jysperm.remove ->
        User.findById jysperm._id, (err, user) ->
          expect(user).to.not.exist
          done err
