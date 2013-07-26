assert = require('chai').assert
{Stream} = require '../jnoid.coffee.md'

describe 'EventStream', ->
  it 'creates simple sequential stream', (done)->
    expectEvents [1, 2, 3],
      Stream.sequentially(10, [1, 2, 3]),
      done

  it 'can be subscribed twice', (done)->
    i = 0
    donner = -> done() if ++i == 2
    stream = Stream.sequentially(10, [1, 2, 3])
    expectEvents [1, 2, 3], stream, donner
    setTimeout((-> expectEvents([2, 3], stream, donner)), 15)

expectEvents = (expected, stream, done)->
  actual = []
  verify = ->
    assert.deepEqual actual, expected
    actual = []
    done()
  stream.subscribe (event)->
    if event.isEmpty()
      verify()
    else
      actual.push event.value
