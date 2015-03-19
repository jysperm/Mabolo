describe 'model.update', ->
  mabolo = new Mabolo mongodb_uri

  User = mabolo.model 'User',
    name: String
    age: Number

  jysperm_id = null

  beforeEach ->
    User.remove
      name:
        $in: ['jysperm', 'we_cry']
    .then ->
      Q.all [
        User.create name: 'jysperm', age: 19
        User.create name: 'we_cry', age: 20
      ]
    .spread ({_id}) ->
      jysperm_id = _id

  describe '.update', ->
    it 'update a document', ->
      User.update
        name: 'jysperm'
      ,
        $inc:
          age: 1
      .then ->
        User.findOne
          name: 'jysperm'
      .then (jysperm) ->
        jysperm.age.should.be.equal 20

    it 'update multi documents', ->
      User.update {},
        $set:
          age: 21
      ,
        multi: true
      .then ->
        User.find
          name:
            $in: ['jysperm', 'we_cry']
      .then (users) ->
        _.pluck(users, 'age').should.be.eql [21, 21]

    it 'update not exists', ->
      User.update
        name: 'orzfly'
      ,
        $set:
          age: 19

  describe '.remove', ->
    it 'remove a document', ->
      User.remove
        name: 'jysperm'
      .then ->
        User.findOne
          name: 'jysperm'
      .then (jysperm) ->
        expect(jysperm).to.not.exists

  describe '.findOneAndUpdate', ->
    it 'update a document', ->
      User.findOneAndUpdate
        name: 'jysperm'
      ,
        $inc:
          age: 1
      .then (jysperm) ->
        jysperm.age.should.be.equal 20

  describe '.findByIdAndUpdate', ->
    it 'update a document', ->
      User.findByIdAndUpdate jysperm_id,
        $inc:
          age: 1
      .then (jysperm) ->
        jysperm.age.should.be.equal 20

  describe '.findOneAndRemove', ->
    it 'remove a document', ->
      User.findOneAndRemove
        name: 'jysperm'
      .then ->
        User.find
          name: 'jysperm'
      .then (jysperm) ->
        expect(jysperm).to.not.exists

  describe '.findByIdAndRemove', ->
    it 'remove a document', ->
      User.findByIdAndRemove(jysperm_id).then ->
        User.find
          name: 'jysperm'
      .then (jysperm) ->
        expect(jysperm).to.not.exists
