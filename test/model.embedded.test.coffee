describe.skip 'model.embedded', ->
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
