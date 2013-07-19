require 'coffee-script'
assert = require('chai').assert
Jnoid = require '../src/jnoid'

describe 'fromDOM', ->
  it 'exists', ->
    assert.isFunction Jnoid.fromDOM

describe 'more and noMore', ->
  it 'is the same', ->
    assert.equal(Jnoid.more, Jnoid.more)
    assert.equal(Jnoid.noMore, Jnoid.noMore)
  it 'is different', ->
    assert.notEqual(Jnoid.more, Jnoid.noMore)

describe 'fromArray', ->
  it 'works', (done)->
    expectEvents [1, 2, 3],
      Jnoid.fromList([1, 2, 3]),
      done


expectEvents = (expectedEvents, stream, done) ->
  events = []
  stream.onValue (event) -> 
    if event.isEnd()
      assert.deepEqual(expectedEvents, events)
      done()
    else
      events.push(event.value)

