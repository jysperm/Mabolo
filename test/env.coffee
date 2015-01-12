process.env.NODE_ENV = 'test'

chai = require 'chai'
_ = require 'underscore'

if process.env.COV_TEST == 'true'
  (require 'coffee-coverage').register
    path: 'relative'
    basePath: "#{__dirname}/.."
    exclude: ['test', 'node_modules', '.git']

_.extend global,
  expect: chai.expect
  _: _

chai.should()
chai.config.includeStack = true
