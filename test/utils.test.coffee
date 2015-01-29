utils = require '../utils'

describe 'utils', ->
  it 'addPrefixForUpdates', ->
    updates = {}
    document = {}

    utils.addPrefixForUpdates updates, document

    updates.should.be.eql {}

    updates =
      v: 1

    document =
      _path: 'path'

    utils.addPrefixForUpdates updates, document

    updates.should.be.eql
      'path.v': 1

    updates =
      $set:
        x: 1
        y: 2
      $inc:
        z: 3

    utils.addPrefixForUpdates updates, document

    updates.should.be.eql
      $set:
        'path.x': 1
        'path.y': 2
      $inc:
        'path.z': 3

    updates =
      $push:
        'arr':
          x: 1
          y: 2

    utils.addPrefixForUpdates updates, document

    updates.should.be.eql
      $push:
        'path.arr':
          x: 1
          y: 2

    updates =
      $addToSet:
        'arr':
          $each: [1, 2, 3]

    utils.addPrefixForUpdates updates, document

    updates.should.be.eql
      $addToSet:
        'path.arr':
          $each: [1, 2, 3]

    updates =
      $set:
        x: 1
        y: 2
      $inc:
        z: 3

    document =
      _path: 'arr'
      _index: 1

    utils.addPrefixForUpdates updates, document

    updates.should.be.eql
      $set:
        'arr.$.x': 1
        'arr.$.y': 2
      $inc:
        'arr.$.z': 3
