assert = require('chai').assert
h = require('./test_helpers')
Jnoid = require '../jnoid'
{Event, Value, Error, End, Stream} = Jnoid

success = undefined
fail = undefined
promise = {
  then: (s, f) ->
    success = s
    fail = f
}

nop = ->

describe "Stream.fromPromise", ->
  it "produces value and ends on success", (done)->
    h.expectValues ["A"],
      Stream.fromPromise(promise),
      done
    success("A")

  it "ends on error", (done)->
    h.expectErrors ["E"],
      Stream.fromPromise(promise),
      done
    fail("E")

  it "unsubscribes", ->
    events = []
    unsub = Stream.fromPromise(promise).subscribe((e) => events.push(e))
    unsub()
    success("A")
    assert.deepEqual(events, [])

  it "aborts on unsubscribe", ->
    isAborted = false
    promise.abort = ->
      isAborted = true
    unsub = Stream.fromPromise(promise).subscribe(nop)
    unsub()
    delete promise.abort
    assert.equal(isAborted, true)
