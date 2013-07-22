assert = require('chai').assert
Jnoid = require '../src/jnoid.coffee.md'

module.exports =
  expectEvents: (expectedEvents, stream, done)->
    events = []
    stream.subscribe (event) ->
      if event.isEnd()
        assert.deepEqual(events, expectedEvents)
        done()
      else
        events.push(event)

  expectValues: (expectedValues, stream, done)->
    @expectEvents(@allValues(expectedValues), stream, done)

  expectErrors: (expectedValues, stream, done)->
    @expectEvents(@allErrors(expectedValues), stream, done)

  value: (x)-> new Jnoid.Value(x)
  error: (x)-> new Jnoid.Error(x)
  allValues: (xs)-> @value(x) for x in xs
  allErrors: (xs)-> @error(x) for x in xs

