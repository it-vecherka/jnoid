assert = require('chai').assert
{Stream} = require '../jnoid.coffee.md'

describe 'EventStream', ->
  describe 'basics', ->
    it 'creates simple sequential stream', (done)->
      expectEvents [1, 2, 3],
        Stream.sequentially(10, [1, 2, 3]),
        done

    it 'can be subscribed twice', (done)->
      i = 0
      donner = -> done() if ++i >= 2
      stream = Stream.sequentially(10, [1, 2, 3])
      expectEvents [1, 2, 3], stream, donner
      setTimeout((-> expectEvents([2, 3], stream, donner)), 15)

  describe 'transformation', ->
    it 'map maps events', (done)->
      expectEvents [10, 20, 30],
        Stream.sequentially(10, [1, 2, 3]).map((x)-> x*10),
        done

    it 'filter filters events', (done)->
      expectEvents [1, 3],
        Stream.sequentially(10, [1, 2, 3]).filter((x)-> x % 2 != 0 ),
        done

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
