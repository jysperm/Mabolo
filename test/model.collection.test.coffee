describe 'model.collection', ->
  mabolo = new Mabolo mongodb_uri

  User = mabolo.model 'User',
    name: String

  describe '.collection', ->
    it 'get collection', (done) ->
      User.collection().then (collection) ->
        collection.stats.should.be.instanceof Function
      .nodeify done

  describe '.ensureIndex', ->
    before (done) ->
      User.collection().then (collection) ->
        collection.dropAllIndexes done

    it 'create index', (done) ->
      User.ensureIndex
        name: 1
      .nodeify done
