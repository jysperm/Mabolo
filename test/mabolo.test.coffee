describe 'Mabolo', ->
  describe '#connect', ->
    it 'constructor with uri', (done) ->
      mabolo = new Mabolo mongodb_uri
      mabolo.connect().nodeify done

    it 'constructor without uri (callback style)', (done) ->
      mabolo = new Mabolo()
      mabolo.connect mongodb_uri, (err, db) ->
        db.should.be.exist
        done err

    it 'constructor without uri (promise style)', (done) ->
      mabolo = new Mabolo()
      mabolo.connect(mongodb_uri).nodeify done

  describe '#model', ->
