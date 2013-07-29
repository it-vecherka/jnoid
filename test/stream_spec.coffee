assert = require('chai').assert
h = require('./test_helpers')
{Stream} = require '../jnoid.coffee.md'

describe 'EventStream', ->
  describe 'basics', ->
    it 'creates simple sequential stream', (done)->
      h.expectValues [1, 2, 3],
        Stream.sequentially(10, [1, 2, 3]),
        done

    it 'can be subscribed twice', (done)->
      i = 0
      donner = -> done() if ++i >= 2
      stream = Stream.sequentially(10, [1, 2, 3])
      h.expectValues [1, 2, 3], stream, donner
      setTimeout((-> h.expectValues([2, 3], stream, donner)), 15)

  describe 'unit', ->
    it 'never creates empty stream', (done)->
      h.expectValues [], Stream.never(), done

    it 'once creates simple stream', (done)->
      h.expectValues [5], Stream.once(5), done

    it 'unit is once', (done)->
      h.expectValues [5], Stream.unit(5), done

  describe 'transformation', ->
    it 'map maps events', (done)->
      h.expectValues [10, 20, 30],
        Stream.sequentially(10, [1, 2, 3]).map((x)-> x*10),
        done

    it 'filter filters events', (done)->
      h.expectValues [1, 3],
        Stream.sequentially(10, [1, 2, 3]).filter((x)-> x % 2 != 0 ),
        done

    it 'flatMap collects all the values from spawned streams', (done)->
      stream = Stream.sequentially(10, [1, 2, 3])
      h.expectValues [10, 100, 20, 200, 30, 300],
        stream.flatMap((x)-> Stream.sequentially(8, [10*x, 100*x])),
        done

    it 'flatMapLast collects only the values from last spawned streams', (done)->
      stream = Stream.sequentially(10, [1, 2, 3])
      h.expectValues [10, 20, 30, 300],
        stream.flatMapLast((x)-> Stream.sequentially(8, [10*x, 100*x])),
        done

  describe 'combination', ->
    it 'merge merges streams', (done)->
      first = Stream.sequentially(10, [1, 2, 3])
      second = Stream.sequentially(13, [10, 20, 30])
      third = Stream.sequentially(19, [100, 200, 300])
      h.expectValues [1, 10, 100, 2, 20, 3, 200, 30, 300],
        first.merge(second, third),
        done


# h.expectValues = (expected, stream, done)->
#   actual = []
#   verify = ->
#     assert.deepEqual actual, expected
#     actual = []
#     done()
