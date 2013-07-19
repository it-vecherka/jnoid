require 'coffee-script'
assert = require('chai').assert

H = {}
H.expectEvents = (expectedEvents, stream, done)->
  events = []
  stream.onValue (event) ->
    if event.isEnd()
      assert.deepEqual(events, expectedEvents)
      done()
    else
      events.push(event.value)

module.exports = H
