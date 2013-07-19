assert = require('chai').assert
Jnoid = require '../src/jnoid'

H = {}
H.expectEvents = (expectedEvents, stream, done)->
  events = []
  stream.onValue (event) ->
    if event.isEnd()
      assert.deepEqual(events, expectedEvents)
      done()
    else
      events.push(event)

H.expectNext = (expectedValues, stream, done)->
  H.expectEvents(H.allNext(expectedValues), stream, done)

H.expectErrors = (expectedValues, stream, done)->
  H.expectEvents(H.allErrors(expectedValues), stream, done)

H.next = Jnoid.next
H.error = Jnoid.error
H.allNext = (xs)-> H.next(x) for x in xs
H.allErrors = (xs)-> H.error(x) for x in xs

module.exports = H
