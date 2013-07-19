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

describe 'unit', ->
  it 'sends a single event', (done)->
    expectEvents [1],
      Jnoid.unit(1),
      done

  it 'does not send anything with no arguments', (done)->
    expectEvents [],
      Jnoid.unit(),
      done

describe 'flatMap', ->
  it 'combines spawned streams (trivial case)', (done)->
    stream = Jnoid.fromList([1, 2, 3])
    expectEvents [1, 2, 3],
      stream.flatMap((x)-> Jnoid.unit(x)),
      done

  it 'can be aliased as bind', (done)->
    stream = Jnoid.fromList([1, 2, 3])
    expectEvents [1, 2, 3],
      stream.bind((x)-> Jnoid.unit(x)),
      done

describe 'map', ->
  it 'transforms values', (done)->
    stream = Jnoid.fromList([1, 2, 3])
    expectEvents [2, 4, 6],
      stream.map((x)-> x * 2),
      done

describe 'merge', ->
  it 'merges lots of streams', (done)->
    first = Jnoid.fromList([1, 2, 3])
    second = Jnoid.fromList([10, 20, 30])
    third = Jnoid.fromList([100, 200, 300])
    expectEvents [1, 2, 3, 10, 20, 30, 100, 200, 300],
      first.merge(second, third),
      done

expectEvents = (expectedEvents, stream, done)->
  events = []
  stream.onValue (event) ->
    if event.isEnd()
      assert.deepEqual(events, expectedEvents)
      done()
    else
      events.push(event.value)

