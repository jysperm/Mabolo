process.env.NODE_ENV = 'test'

chai = require 'chai'
_ = require 'underscore'

_.extend global,
  mongodb_uri: 'mongodb://localhost/mabolo_test'
  Mabolo: require '../index'
  expect: chai.expect
  _: _

chai.should()
chai.config.includeStack = true
