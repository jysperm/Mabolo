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
          required: true
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

    it 'toObject should success', ->
      jysperm.toObject().last_token.code.should.be.equal '03b9a5f0d18bc6b6'
      jysperm.toObject().last_token.should.not.instanceof Token

    it 'should success when update sub-document'

    it 'should fail when sub-document validating fail', (done) ->
      User.create
        username: 'faceair'
        last_token:
          code: 1024
      , (err) ->
        err.should.be.exist
        done()

    it 'should fail when missing sub-document', (done) ->
      User.create
        username: 'faceair'
      , (err) ->
        err.should.be.exist
        done()

  describe 'embedded array of string', ->
    User = null

    before ->
      User = mabolo.model 'User',
        username:
          type: String

        tags: [String]

    it 'should success when save', (done) ->
      jysperm = new User
        username: 'jysperm'
        tags: ['node.js', 'php']

      jysperm.save done

    it 'should success when save empty array', (done) ->
      User.create
        username: 'faceair'
      , done

  describe 'embedded array of model', ->
    Token = null
    User = null

    before ->
      Token = mabolo.model 'Token',
        code:
          type: String

      Token::getCode = ->
        return @code

      User = mabolo.model 'User',
        username:
          type: String

        tokens: [Token]

    it 'should success use create', (done) ->
      User.create
        username: 'jysperm'
        tokens: [
          code: '1'
        ,
          code: '2'
        ]
      , (err, jysperm) ->
        jysperm.tokens.length.should.be.equal 2
        jysperm.tokens[0]._id.should.be.exist
        jysperm.tokens[1].getCode().should.be.equal '2'
        done err

    it 'should success use constructor', (done) ->
      token = new Token
        code: '3'

      jysperm = new User
        username: 'jysperm'
        tokens: [token]

      jysperm.toObject().tokens[0].should.not.instanceof Token

      jysperm.save (err) ->
        jysperm.tokens[0].should.be.instanceof Token
        done err
