Mabolo = require '../index'

mongodb_uri = 'mongodb://localhost/mabolo_test'

randomNumber = (length) ->
  num = parseInt(Math.random() * Math.pow(10, length)).toString()
  return new Array(length - num.length + 1).join('0') + num

describe 'mabolo', ->
  describe 'Mabolo', ->
    mabolo = null

    it '#constructor', ->
      mabolo = new Mabolo mongodb_uri

    it '#model', ->
      User = mabolo.model 'User',
        username:
          type: String

      User._options.collection_name.should.be.equal 'users'

  describe 'Model', ->
    mabolo = null
    Account = null
    mobile = randomNumber 11

    before ->
      mabolo = new Mabolo mongodb_uri

      Account = mabolo.model 'Account',
        username:
          type: String

    it '#constructor', ->
      account = new Account
        username: 'jysperm'

      account.username.should.be.equal 'jysperm'
      account.toObject().should.be.eql
        username: 'jysperm'

    it '#create', (done) ->
      Account.create
        username: 'jysperm'
        mobile: mobile
      , (err, account) ->
        account._id.should.be.exist
        account.username.should.be.equal 'jysperm'
        done err

    it '#findOne', (done) ->
      Account.findOne
        mobile: mobile
      , (err, account) ->
        account.username.should.be.equal 'jysperm'
        done err

    it '#find', (done) ->
      Account.find
        mobile: mobile
      , (err, accounts) ->
        accounts[0].username.should.be.equal 'jysperm'
        done err
