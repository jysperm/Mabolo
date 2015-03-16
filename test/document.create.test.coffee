describe 'document.create', ->
  mabolo = new Mabolo mongodb_uri
  {ObjectID} = mabolo

  User = mabolo.model 'User',
    name: String

  describe '#constructor', ->
    jysperm = null

    it 'create document', ->
      jysperm = new User
        name: 'jysperm'

      jysperm.name.should.be.equal 'jysperm'
      jysperm.should.be.instanceof User

    it 'save document', (done) ->
      jysperm.save().then ->
        jysperm._id.should.be.instanceof ObjectID
        jysperm.__v.should.be.a 'string'
      .nodeify done

  describe '#create', ->
    it 'create document', (done) ->
      User.create
        name: 'faceair'
      .then (faceair) ->
        faceair.name.should.be.equal 'faceair'
        faceair._id.should.be.instanceof ObjectID
        faceair.__v.should.be.a 'string'
      .nodeify done
