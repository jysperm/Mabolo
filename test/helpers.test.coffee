describe 'helpers', ->
  {helpers} = Mabolo

  it 'addPrefixForUpdates', ->
    {addPrefixForUpdates} = helpers

    addPrefixForUpdates({}, {}).should.be.eql {}

    addPrefixForUpdates(
      _path: 'path'
    ,
      v: 1
    ).should.be.eql
      'path.v': 1

    addPrefixForUpdates(
      _path: 'path'
    ,
      $set:
        x: 1
        y: 2
      $inc:
        z: 3
    ).should.be.eql
      $set:
        'path.x': 1
        'path.y': 2
      $inc:
        'path.z': 3

    addPrefixForUpdates(
      _path: 'path'
    ,
      $push:
        'arr':
          x: 1
          y: 2
    ).should.be.eql
      $push:
        'path.arr':
          x: 1
          y: 2

    addPrefixForUpdates(
      _path: 'path'
    ,
      $addToSet:
        'arr':
          $each: [1, 2, 3]
    ).should.be.eql
      $addToSet:
        'path.arr':
          $each: [1, 2, 3]

    addPrefixForUpdates(
      _path: 'arr'
      _index: 1
    ,
      $set:
        x: 1
        y: 2
      $inc:
        z: 3
    ).should.be.eql
      $set:
        'arr.$.x': 1
        'arr.$.y': 2
      $inc:
        'arr.$.z': 3
