assert = require('chai').assert
Jnoid = require '../src/jnoid'

module.exports =
  expectEvents: (expectedEvents, stream, done)->
    events = []
    stream.onValue (event) ->
      if event.isEnd()
        assert.deepEqual(events, expectedEvents)
        done()
      else
        events.push(event)

  expectNext: (expectedValues, stream, done)->
    @expectEvents(@allNext(expectedValues), stream, done)

  expectErrors: (expectedValues, stream, done)->
    @expectEvents(@allErrors(expectedValues), stream, done)

  next: Jnoid.next
  error: Jnoid.error
  allNext: (xs)-> @next(x) for x in xs
  allErrors: (xs)-> @error(x) for x in xs

