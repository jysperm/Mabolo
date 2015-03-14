mabolo = new Mabolo mongodb_uri

describe.skip 'model.statics', ->
  jysperm_id = null

  before (done) ->
    User.remove done

  describe 'Model.create', ->
    it 'create jysperm', (done) ->
      User.create
        username: 'jysperm'
        email: 'jysperm@gmail.com'
      , (err, user) ->
        user._id.should.be.exist
        user.username.should.be.equal 'jysperm'
        user.should.be.instanceOf User
        jysperm_id = user._id
        done err

    it 'create faceair', (done) ->
      User.create
        username: 'faceair'
      , done

  describe 'Model.getCollection', ->
    it 'getCollection', ->
      User.getCollection().constructor.name.should.be.equal 'Collection'

  describe 'Model.transform', ->
    it 'transform', ->
      User.transform(
        username: 'orzfly'
      ).should.be.instanceOf User

  describe 'Model.find', ->
    it 'find all', (done) ->
      User.find (err, users) ->
        _.findWhere(users,
          username: 'jysperm'
        ).should.be.exist
        _.findWhere(users,
          username: 'faceair'
        ).should.be.exist
        done err

    it 'find jysperm', (done) ->
      User.find
        username: 'jysperm'
      , (err, users) ->
        users.length.should.be.equal 1
        _.findWhere(users,
          username: 'jysperm'
        ).should.be.exist
        done err

  describe 'Model.count', ->
    it 'count', (done) ->
      User.count (err, count) ->
        count.should.be.equal 2
        done err

  describe 'Model.findOne', ->
    it 'findOne', (done) ->
      User.findOne
        username: 'jysperm'
      , (err, user) ->
        user.email.should.be.equal 'jysperm@gmail.com'
        done err

  describe 'Model.findById', ->
    it 'findById with ObjectID', (done) ->
      User.findById jysperm_id, (err, user) ->
        user.username.should.be.equal 'jysperm'
        done err

    it 'findById with string', (done) ->
      User.findById jysperm_id.toString(), (err, user) ->
        user.username.should.be.equal 'jysperm'
        done err

    it 'findById with invalid ObjectID', (done) ->
      User.findById '1234', (err, user) ->
        err.should.be.exist
        expect(user).to.not.exist
        done()

  describe 'Model.findOneAndUpdate', ->
    it 'findOneAndUpdate', (done) ->
      User.findOneAndUpdate
        username: 'jysperm'
      ,
        $set:
          email: 'jysperm@outlook.com'
      , (err, user) ->
        user.email.should.be.equal 'jysperm@outlook.com'
        done err

    it 'with options.new is false', (done) ->
      User.findOneAndUpdate
        username: 'faceair'
      ,
        $set:
          email: 'faceair@pomotodo.com'
      ,
        new: false
      , (err, user) ->
        expect(user.email).to.not.exist
        done err

    it 'find not exist document', (done) ->
      User.findOneAndUpdate
        username: 'ming'
      ,
        $set:
          email: 'ming@pomotodo.com'
      , (err, user) ->
        expect(err).to.not.exist
        expect(user).to.not.exist
        done err

  describe 'Model.findByIdAndUpdate', ->
    it 'findByIdAndUpdate', (done) ->
      User.findByIdAndUpdate jysperm_id,
        $set:
          email: 'jysperm@jysperm.me'
      , (err, user) ->
        user.email.should.be.equal 'jysperm@jysperm.me'
        done err

  describe 'Model.findByIdAndRemove', ->
    it 'findByIdAndRemove', (done) ->
      User.findByIdAndRemove jysperm_id, (err) ->
        User.findById jysperm_id, (err, user) ->
          expect(user).to.not.exist
          done err
