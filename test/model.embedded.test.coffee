mabolo = new Mabolo mongodb_uri

describe 'model.embedded', ->
  describe 'embedded model', ->
    Token = null
    User = null
    jysperm = null

    before ->
      Token = mabolo.model 'Token',
        code:
          type: String

      Token::getCode = ->
        return @code

      User = mabolo.model 'User',
        username:
          type: String

        last_token:
          type: Token

    it 'should build sub-document when created', ->
      jysperm = new User
        username: 'jysperm'
        last_token:
          code: '03b9a5f0d18bc6b6'

      jysperm.last_token.should.be.instanceof Token
      jysperm.last_token.getCode().should.be.equal '03b9a5f0d18bc6b6'
      jysperm.last_token._id.should.be.exist

    it 'should success when save', (done) ->
      jysperm.save (err) ->
        jysperm._id.should.be.exist
        jysperm.last_token.should.be.instanceof Token
        done err

    it 'should fail when sub-document validating fail', (done) ->
      User.create
        username: 'faceair'
        last_token:
          code: 1024
      , (err) ->
        err.should.be.exist
        done()

  describe 'embedded array of string', ->

  describe 'embedded array of model', ->
