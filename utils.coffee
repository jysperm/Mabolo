{ObjectID} = require 'mongodb'
crypto = require 'crypto'
_ = require 'underscore'

exports.pass = pass = ->

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

exports.isModel = isModel = (value) ->
  return value?._schema

exports.isEmbedded = exports.isDocument = (value) ->
  return value?._path

exports.isEmbeddedDocument = (value) ->
  return value?._path and !value._index

exports.isEmbeddedArray = (value) ->
  return value?._path and value._index

exports.isInstanceOf = (Type, value) ->
  switch Type
    when String
      return _.isString value

    when Number
      return _.isNumber value

    when Date
      return _.isDate value

    when Boolean
      return _.isBoolean value

    else
      return value instanceof Type

exports.forEachPath = (model, document, iterator) ->
  for path, definition of model._schema
    value = dotGet document, path

    it =
      dotSet: (value) ->
        dotSet document, path, value

      isEmbeddedArrayPath: ->
        return _.isArray definition

      getEmbeddedArrayModel: ->
        return _.first definition

      isEmbeddedDocumentPath: ->
        return isModel definition.type

      getEmbeddedDocumentModel: ->
        return definition.type

    iterator path, value, definition, it

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
