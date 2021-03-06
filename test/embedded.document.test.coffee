describe 'embedded.document', ->
  mabolo = new Mabolo mongodb_uri

  Token = mabolo.model 'Token',
    code: String

  Token::getCode = ->
    return @code

  User = mabolo.model 'User',
    name: String
    token:
      required: true
      type: Token

  describe 'create document', ->
    it 'construct and save', ->
      jysperm = new User
        name: 'jysperm'
        token:
          code: '03b9a5f0d18bc6b6'

      jysperm.token.should.be.instanceof Token
      jysperm.token.getCode().should.be.equal '03b9a5f0d18bc6b6'
      jysperm.token._id.should.be.exists

      jysperm.toObject().token.should.not.instanceof Token

      return jysperm.save()

    it 'create document', ->
      token = new Token
        code: '03b9a5f0d18bc6b6'

      User.create
        name: 'jysperm'
        token: token
      . then (jysperm) ->
        jysperm.token.should.be.instanceof Token
        jysperm.token.getCode().should.be.equal '03b9a5f0d18bc6b6'
        jysperm.token._id.should.be.exists

    it 'create when validating fail', (done) ->
      User.create
        name: 'jysperm'
        token:
          code: 1024
      , (err) ->
        err.should.be.match /code/
        done()

    it 'create when missing embedded document', (done) ->
      User.create
        name: 'jysperm'
      , (err) ->
        err.should.be.match /token/
        done()

  describe 'update document', ->
    it 'update document', ->
      User.create
        name: 'jysperm'
        token:
          code: '03b9a5f0d18bc6b6'
      .then (jysperm) ->
        jysperm.token.update
          $set:
            code: 'updated'
        .then (token) ->
          token.code.should.be.equal 'updated'
          User.findById(jysperm._id).then (jysperm) ->
            jysperm.token.code.should.be.equal 'updated'

  describe 'modify document', ->
    it 'modify document', ->
      User.create
        name: 'jysperm'
        token:
          code: '03b9a5f0d18bc6b6'
      .then (jysperm) ->
        jysperm.token.modify ->
          jysperm.token.code = 'updated'
        .then (token) ->
          token.code.should.be.equal 'updated'

  describe 'remove document', ->
    it 'remove document', ->
      User.create
        name: 'jysperm'
        token:
          code: '03b9a5f0d18bc6b6'
      .then (jysperm) ->
        jysperm.token.remove().then ->
          expect(jysperm.token).to.not.exists
          User.findById(jysperm._id).then (jysperm) ->
            expect(jysperm.token).to.not.exists
