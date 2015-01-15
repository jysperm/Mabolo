mabolo = new Mabolo mongodb_uri

User = mabolo.model 'User',
  username:
    type: String

  email:
    type: String

describe 'model.methods', ->
  jysperm = null

  describe 'model.constructor', ->
    it 'create jysperm', (done) ->
      jysperm = new User
        username: 'jysperm'

      jysperm.username.should.be.equal 'jysperm'
      jysperm.toObject().should.be.eql
        username: 'jysperm'

      jysperm.save (err) ->
        jysperm._id.should.be.exist
        done err

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
