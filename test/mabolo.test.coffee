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
    account_id = null

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
        account_id = account._id
        done err

    it '#findOne', (done) ->
      Account.findOne
        mobile: mobile
      , (err, account) ->
        account.username.should.be.equal 'jysperm'
        account.should.be.instanceOf Account
        done err

    it '#find', (done) ->
      Account.find
        mobile: mobile
      , (err, accounts) ->
        accounts[0].username.should.be.equal 'jysperm'
        accounts[0].should.be.instanceOf Account
        done err

    it '#count', (done) ->
      Account.count (err, count) ->
        (count >= 1).should.be.true
        done err

    it '#findById with ObjectID', (done) ->
      Account.findById account_id, (err, account) ->
        account.mobile.should.be.equal mobile
        done err

    it '#findById with string', (done) ->
      Account.findById account_id.toString(), (err, account) ->
        account.mobile.should.be.equal mobile
        done err

    it '#findById with invalid ObjectId', (done) ->
      Account.findById 'object_id', (err, account) ->
        expect(account).to.not.exist
        err.should.be.exist
        done()

    it '#buildDocument', ->
      Account.buildDocument(
        username: 'faceair'
      ).toObject().username.should.be.equal 'faceair'

    it '#getCollection', ->
      Account.getCollection().constructor.name.should.be.equal 'Collection'

    it '#findOneAndUpdate', (done) ->
      Account.findOneAndUpdate
        mobile: mobile
      ,
        $set:
          username: 'Jysperm'
      , (err, account) ->
        account.username.should.be.equal 'Jysperm'
        done err

    it '#findOneAndUpdate when options.new is false', (done) ->
      Account.findOneAndUpdate
        mobile: mobile
      ,
        $set:
          username: 'Jysperm'
      ,
        new: false
      , (err, account) ->
        account.username.should.be.equal 'Jysperm'
        done err

    it '#findByIdAndUpdate', (done) ->
      Account.findByIdAndUpdate account_id,
        $set:
          username: 'Wang Ziting'
      , (err, account) ->
        account.username.should.be.equal 'Wang Ziting'
        done err

    it '#findByIdAndRemove', (done) ->
      Account.findByIdAndRemove account_id, (err) ->
        Account.findById account_id, (err, account) ->
          expect(account).to.not.exist
          done err

  describe 'model', ->
    mabolo = null
    Account = null
    mobile = randomNumber 11
    account = null

    before (done) ->
      mabolo = new Mabolo mongodb_uri

      Account = mabolo.model 'Account',
        username:
          type: String

      Account.create
        username: 'jysperm'
        mobile: mobile
      , (err, _account) ->
        account = _account
        done err

    it '#save', (done) ->
      yudong = new Account username: 'yudong'

      yudong.save (err) ->
        yudong._id.should.be.exist
        done err

    it '#update', (done) ->
      account.update
        $set:
          username: 'Jysperm'
      , (err) ->
        account.username.should.be.equal 'Jysperm'
        done err

    it '#remove', (done) ->
      account.remove ->
        Account.findById account._id, (err, account) ->
          expect(account).to.not.exist
          done err
