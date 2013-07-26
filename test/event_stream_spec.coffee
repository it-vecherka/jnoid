assert = require('chai').assert
{EventStream} = require '../jnoid.coffee.md'

describe 'EventStream', ->
  it 'creates simple sequential stream', (done)->
    expectEvents [1, 2, 3],
      EventStream.sequentially(10, [1, 2, 3]),
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
