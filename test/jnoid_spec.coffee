require 'coffee-script'
assert = require('chai').assert
Jnoid = require "../src/jnoid"

describe "fromDOM", ->
  it "exists", ->
    assert.isFunction Jnoid.fromDOM
