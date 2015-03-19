describe 'model.collection', ->
  mabolo = new Mabolo mongodb_uri

  User = mabolo.model 'User',
    name: String

  describe '.collection', ->
    it 'get collection', ->
      User.collection().then (collection) ->
        collection.stats.should.be.instanceof Function

  describe '.ensureIndex', ->
    before (done) ->
      User.collection().then (collection) ->
        collection.dropAllIndexes done

    it 'create index', ->
      User.ensureIndex
        name: 1
