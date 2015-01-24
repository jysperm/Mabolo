{ObjectID} = require 'mongodb'
crypto = require 'crypto'

exports.pass = ->

exports.dotGet = dotGet = (object, path) ->
  paths = path.split '.'
  ref = object

  for key in paths
    if ref[key] == undefined
      return undefined
    else
      ref = ref[key]

  return ref

exports.dotSet = dotSet = (object, path, value) ->
  paths = path.split '.'
  last_path = paths.pop()
  ref = object

  for key in paths
    ref[key] ?= {}
    ref = ref[key]

  ref[last_path] = value

exports.dotPick = (object, keys) ->
  result = {}

  for key in keys
    if dotGet(object, key) != undefined
      dotSet result, key, dotGet(object, key)

  return result

exports.randomVersion = randomVersion = ->
  return crypto.pseudoRandomBytes(4).toString 'hex'

exports.addVersionForUpdates = (updates) ->
  is_atom_op = _.every _.keys(updates), (key) ->
    return key[0] == '$'

  if is_atom_op
    updates.$set ?= {}
    updates.$set['__v'] ?= randomVersion()
  else
    updates['__v'] ?= randomVersion()

exports.formatValidators = (validators) ->
  if _.isFunction validators
    validators = [validators]

  else if !_.isArray(validators) and _.isObject(validators)
    validators = _.map validators, (validator, name) ->
      validator.validator_name = name
      return validator

  return validators

exports.isTypeOf = (Type, value) ->
  switch Type
    when String
      unless _.isString value
        return 'is string'

    when Number
      unless _.isNumber value
        return 'is number'

    when Date
      unless _.isDate value
        return 'is date'

    when Boolean
      unless _.isBoolean value
        return 'is boolean'

    when ObjectID
      unless value instanceof ObjectID
        return 'is objectid'

    when Object
      pass

    else
      throw new Error "unknown type #{Type.toString()}}"

  return null

exports.isModel = (value) ->
  return value?._schema

exports.isEmbedded = (value) ->
  return value?._path

exports.isEmbeddedDocument = (value) ->
  return value?._path and !value._index

exports.isEmbeddedArray = (value) ->
  return value?._path and value._index
