describe 'Mabolo', ->
  mabolo = null

  it 'Mabolo.constructor', ->
    mabolo = new Mabolo mongodb_uri

  it 'Mabolo.model', ->
    User = mabolo.model 'User',
      username:
        type: String

    User._options.collection_name.should.be.equal 'users'

    Ticket = mabolo.model 'Ticket', null,
      collection_name: 'ticket'

    Ticket._options.collection_name.should.be.equal 'ticket'

  it 'Mabolo.connect', (done) ->
    do (mabolo) ->
      mabolo = new Mabolo()

      mabolo.connect mongodb_uri, (err, db) ->
        db.should.be.exist
        done err
