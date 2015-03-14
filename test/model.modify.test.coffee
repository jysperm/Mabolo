mabolo = new Mabolo mongodb_uri

User = mabolo.model 'User',
  username: String
  blog: String
  age: Number

describe.skip 'model.modify', ->
  user = null

  it 'save document', (done) ->
    user = new User
      username: 'jysperm'
      age: 19

    user.save done

  it 'modify no conflict', (done) ->
    user.modify (commit) ->
      @age = 20
      commit()
    , (err) ->
      expect(err).to.not.exist
      user.age.should.be.equal 20

      User.findById user._id, (err, user) ->
        user.age.should.be.equal 20
        done err

  it 'modify and rollback', (done) ->
    user.modify (commit) ->
      @age = 21
      commit 'error'
    , (err) ->
      err.should.be.equal 'error'
      user.age.should.be.equal 20

      User.findById user._id, (err, user) ->
        user.age.should.be.equal 20
        done err

  it 'modify when validate fail', (done) ->
    user.modify (commit) ->
      @blog = 'jybox.net'
      @age = 'string'
      commit()
    , (err) ->
      err.should.be.exist
      user.age.should.be.equal 20
      expect(user.blog).to.not.exist

      User.findById user._id, (err, user) ->
        user.age.should.be.equal 20
        expect(user.blog).to.not.exist
        done err

  it 'modify when conflict', (done) ->
    user.modify (commit) ->
      @age = 21

      if @blog
        return commit()

      User.findByIdAndUpdate @_id,
        $set:
          blog: 'jysperm.me'
      , commit

    , (err) ->
      expect(err).to.not.exist
      user.age.should.be.equal 21
      user.blog.should.be.equal 'jysperm.me'

      User.findById user._id, (err, user) ->
        user.age.should.be.equal 21
        user.blog.should.be.equal 'jysperm.me'
        done err
