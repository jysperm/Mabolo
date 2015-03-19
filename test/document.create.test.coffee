describe 'document.create', ->
  mabolo = new Mabolo mongodb_uri
  {ObjectID} = Mabolo

  User = mabolo.model 'User',
    name: String

  describe '#constructor', ->
    jysperm = null

    it 'create document', ->
      jysperm = new User
        name: 'jysperm'

      jysperm.name.should.be.equal 'jysperm'
      jysperm.should.be.instanceof User

    it 'save document', ->
      jysperm.save().then ->
        jysperm._id.should.be.instanceof ObjectID
        jysperm.__v.should.be.a 'string'

  describe '#create', ->
    it 'create document', ->
      User.create
        name: 'faceair'
      .then (faceair) ->
        faceair.name.should.be.equal 'faceair'
        faceair._id.should.be.instanceof ObjectID
        faceair.__v.should.be.a 'string'
