describe 'model.find', ->
  mabolo = new Mabolo mongodb_uri
  {ObjectID} = Mabolo

  User = mabolo.model 'User',
    name: String
    age: Number

  jysperm_id = null

  before (done) ->
    User.remove
      name:
        $in: ['jysperm', 'faceair', 'we_cry', 'yudong']
    .nodeify done

  before (done) ->
    User.create
      name: 'jysperm'
      age: 19
    .then ({_id}) ->
      jysperm_id = _id
    .nodeify done

  before (done) ->
    User.create
      name: 'faceair'
      age: 20
    .nodeify done

  before (done) ->
    User.create
      name: 'we_cry'
      age: 20
    .nodeify done

  before (done) ->
    User.create
      name: 'yudong'
      age: 23
    .nodeify done

  describe '.find', ->
    it 'find all', (done) ->
      User.find().then (users) ->
        for name in ['jysperm', 'faceair', 'we_cry', 'yudong']
          _.findWhere(users, name: name).should.be.exist
      .nodeify done

    it 'find by name', (done) ->
      User.find
        name: 'jysperm'
      .then (users) ->
        users.length.should.be.equal 1
        users[0].age.should.be.equal 19
      .nodeify done

    it 'find by age', (done) ->
      User.find
        age: 20
      .then (users) ->
        for name in ['faceair', 'we_cry']
          _.findWhere(users, name: name).should.be.exist
      .nodeify done

    it 'find by age and sort', (done) ->
      User.find {},
        sort: {age: -1}
        limit: 1
      .then (users) ->
        users.length.should.be.equal 1
        users[0].name.should.be.equal 'yudong'
      .nodeify done

  describe '.findOne', ->
    it 'find by name', (done) ->
      User.findOne
        name: 'jysperm'
      .then (user) ->
        user.age.should.be.equal 19
      .nodeify done

    it 'find not exists', (done) ->
      User.findOne
        name: 'orzfly'
      .then (user) ->
        expect(user).to.not.exist
      .nodeify done

  describe '.findById', ->
    it 'find by id', (done) ->
      User.findById(jysperm_id).then (user) ->
        user.name.should.be.equal 'jysperm'
      .nodeify done

    it 'find by string of id', (done) ->
      User.findById(jysperm_id.toString()).then (user) ->
        user.name.should.be.equal 'jysperm'
      .nodeify done

    it 'find not exists', (done) ->
      User.findById(new ObjectID).then (user) ->
        expect(user).to.not.exist
      .nodeify done

    it 'find invalid id', (done) ->
      User.findById('jysperm').nodeify (err, user) ->
        expect(err).to.be.exist
        expect(user).to.not.exist
        done()

  describe '.count', ->
    it 'count with query', (done) ->
      User.count
        name:
          $in: ['jysperm', 'we_cry', 'orzfly']
      .then (count) ->
        count.should.be.equal 2
      .nodeify done

  describe '.aggregate', ->
    it 'sum of field', (done) ->
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
      .nodeify done
