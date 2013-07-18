require 'coffee-script'
assert = require('chai').assert
J = require "../app"

describe "first test", ->
  it "works!", ->
    assert.isFunction J.fromDOM
