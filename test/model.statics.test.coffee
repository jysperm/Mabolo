mabolo = new Mabolo mongodb_uri

describe.skip 'model.statics', ->
  jysperm_id = null

  before (done) ->
    User.remove done

  describe 'Model.getCollection', ->
    it 'getCollection', ->
      User.getCollection().constructor.name.should.be.equal 'Collection'

  describe 'Model.transform', ->
    it 'transform', ->
      User.transform(
        username: 'orzfly'
      ).should.be.instanceOf User

  describe 'Model.count', ->
    it 'count', (done) ->
      User.count (err, count) ->
        count.should.be.equal 2
        done err

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
