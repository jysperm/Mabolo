describe 'document.modify', ->
  mabolo = new Mabolo mongodb_uri

  User = mabolo.model 'User',
    name: String
    age: Number

  jysperm = null

  beforeEach ->
    User.create
      name: 'jysperm'
      age: 19
    .then (result) ->
      jysperm = result

  it 'modify without conflict', ->
    jysperm.modify (jysperm) ->
      jysperm.age = 20
    .then ->
      User.findById jysperm._id
    .then (jysperm) ->
      jysperm.age.should.be.equal 20

  it 'modify without conflict async', ->
    jysperm.modify (jysperm) ->
      Q.delay(10).then ->
        jysperm.age = 20
    .then ->
      User.findById jysperm._id
    .then (jysperm) ->
      jysperm.age.should.be.equal 20

  it 'modify and rollback', ->
    jysperm.modify (jysperm) ->
      jysperm.age = 20
      return Q.reject new Error 'rollback'
    .catch (err) ->
      err.message.should.match /rollback/
    .thenResolve().then ->
      jysperm.age.should.be.equal 19
      User.findById jysperm._id
    .then (jysperm) ->
      jysperm.age.should.be.equal 19

  it 'modify and validating fail', ->
    jysperm.modify (jysperm) ->
      jysperm.age = 'invalid-number'
    .catch (err) ->
      err.message.should.match /age/
    .thenResolve().then ->
      jysperm.age.should.be.equal 19
      User.findById jysperm._id
    .then (jysperm) ->
      jysperm.age.should.be.equal 19

  it 'modify and conflict', ->
    User.findByIdAndUpdate jysperm._id,
      $set:
        age: 20
    .then ->
      jysperm.modify (jysperm) ->
        jysperm.name = 'JYSPERM'
      .then ->
        jysperm.name.should.be.equal 'JYSPERM'
        jysperm.age.should.be.equal 20
        User.findById jysperm._id
      .then (jysperm) ->
        jysperm.name.should.be.equal 'JYSPERM'
        jysperm.age.should.be.equal 20
