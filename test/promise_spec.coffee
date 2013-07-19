require 'coffee-script'
assert = require('chai').assert
h = require('./test_helpers')
Jnoid = require '../src/jnoid'

success = undefined
fail = undefined
promise = {
  then: (s, f) ->
    success = s
    fail = f
}

nop = ->

describe "Jnoid.fromPromise", ->
  it "produces value and ends on success", (done)->
    h.expectNext ["A"],
      Jnoid.fromPromise(promise),
      done
    success("A")

  it "ends on error", (done)->
    h.expectErrors ["E"],
      Jnoid.fromPromise(promise),
      done
    fail("E")
