describe 'model.find', ->
  mabolo = new Mabolo mongodb_uri
  {ObjectID} = Mabolo

  User = mabolo.model 'User',
    name: String
    age: Number

  jysperm_id = null

  before ->
    User.remove
      name:
        $in: ['jysperm', 'faceair', 'we_cry', 'yudong']

  before ->
    User.create
      name: 'jysperm'
      age: 19
    .then ({_id}) ->
      jysperm_id = _id

  before ->
    Q.all [
      User.create name: 'faceair', age: 20
      User.create name: 'we_cry', age: 20
      User.create name: 'yudong', age: 23
    ]

  describe '.find', ->
    it 'find all', ->
      User.find().then (users) ->
        for name in ['jysperm', 'faceair', 'we_cry', 'yudong']
          _.findWhere(users, name: name).should.be.exist

    it 'find by name', ->
      User.find
        name: 'jysperm'
      .then (users) ->
        users.length.should.be.equal 1
        users[0].age.should.be.equal 19

    it 'find by age', ->
      User.find
        age: 20
      .then (users) ->
        for name in ['faceair', 'we_cry']
          _.findWhere(users, name: name).should.be.exist

    it 'find by age and sort', ->
      User.find {},
        sort: {age: -1}
        limit: 1
      .then (users) ->
        users.length.should.be.equal 1
        users[0].name.should.be.equal 'yudong'

  describe '.findOne', ->
    it 'find by name', ->
      User.findOne
        name: 'jysperm'
      .then (user) ->
        user.age.should.be.equal 19

    it 'find not exists', ->
      User.findOne
        name: 'orzfly'
      .then (user) ->
        expect(user).to.not.exist

  describe '.findById', ->
    it 'find by id', ->
      User.findById(jysperm_id).then (user) ->
        user.name.should.be.equal 'jysperm'

    it 'find by string of id', ->
      User.findById(jysperm_id.toString()).then (user) ->
        user.name.should.be.equal 'jysperm'

    it 'find not exists', ->
      User.findById(new ObjectID).then (user) ->
        expect(user).to.not.exist

    it 'find invalid id', (done) ->
      User.findById('jysperm').nodeify (err, user) ->
        expect(err).to.be.exist
        expect(user).to.not.exist
        done()

  describe '.count', ->
    it 'count with query', ->
      User.count
        name:
          $in: ['jysperm', 'we_cry', 'orzfly']
      .then (count) ->
        count.should.be.equal 2

  describe '.aggregate', ->
    it 'sum of field', ->
      User.aggregate([
        $match:
          name:
            $in: ['jysperm', 'we_cry', 'faceair']
      ,
        $group:
          _id: null
          total:
            $sum: '$age'
      ]).then ([{total}]) ->
        total.should.be.equal 59
