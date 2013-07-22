assert = require('chai').assert
h = require('./test_helpers')
Jnoid = require '../jnoid.coffee.md'
{Event, Value, Error, End} = Jnoid

describe 'more and noMore', ->
  it 'is the same', ->
    assert.equal(Jnoid.more, Jnoid.more)
    assert.equal(Jnoid.noMore, Jnoid.noMore)

  it 'is different', ->
    assert.notEqual(Jnoid.more, Jnoid.noMore)


describe 'Event', ->
  describe 'Value', ->
    it 'is value, is not error, is not end', ->
      event = new Value 5
      assert.ok(event.isValue())
      assert.notOk(event.isError())
      assert.notOk(event.isEnd())

    it 'returns value', ->
      event = new Value 5
      assert.equal(event.value, 5)

    it 'filters value', ->
      assert.ok(new Value(5).filter((x)-> x < 10))
      assert.notOk(new Value(15).filter((x)-> x < 10))

    it 'fmaps value', ->
      assert.deepEqual(new Value(5).fmap((x) -> x + 5),
        new Value(10))

  describe 'Error', ->
    it 'is not a value, is error, is not end', ->
      event = new Error 'whut'
      assert.notOk(event.isValue())
      assert.ok(event.isError())
      assert.notOk(event.isEnd())

    it 'returns error', ->
      event = new Error 'whut'
      assert.equal(event.error, 'whut')

    it 'does not filter', ->
      assert.ok(new Error('whut').filter((x)-> x < 10))

    it 'does not fmap', ->
      assert.deepEqual(new Error('whut').fmap((x) -> x + 5),
        new Error('whut'))

  describe 'End', ->
    it 'is not a value, is not an error, is end', ->
      event = new End
      assert.notOk(event.isValue())
      assert.notOk(event.isError())
      assert.ok(event.isEnd())

    it 'does not filter', ->
      assert.ok(new End().filter((x)-> x < 10))

    it 'does not fmap', ->
      assert.deepEqual(new End().fmap((x) -> x + 5), new End)

describe 'fromList', ->
  it 'works', (done)->
    h.expectValues [1, 2, 3],
      Jnoid.fromList([1, 2, 3]),
      done

describe 'unit', ->
  it 'sends a single event', (done)->
    h.expectValues [1],
      Jnoid.unit(1),
      done

  it 'does not send anything with no arguments', (done)->
    h.expectValues [],
      Jnoid.unit(),
      done

describe 'map', ->
  it 'transforms values', (done)->
    stream = Jnoid.fromList([1, 2, 3])
    h.expectValues [2, 4, 6],
      stream.map((x)-> x * 2),
      done

describe 'flatMap', ->
  it 'combines spawned streams (trivial case)', (done)->
    stream = Jnoid.fromList([1, 2, 3])
    h.expectValues [1, 2, 3],
      stream.flatMap((x)-> Jnoid.unit(x)),
      done

describe 'merge', ->
  it 'merges lots of streams', (done)->
    first = Jnoid.fromList([1, 2, 3])
    second = Jnoid.fromList([10, 20, 30])
    third = Jnoid.fromList([100, 200, 300])
    h.expectValues [1, 2, 3, 10, 20, 30, 100, 200, 300],
      first.merge(second, third),
      done

describe 'delay', ->
  it 'sends all events after a delay', (done)->
    first = Jnoid.fromList([1, 2, 3]).delay(10)
    second = Jnoid.fromList([10, 20, 30])
    h.expectValues [10, 20, 30, 1, 2, 3],
      first.merge(second),
      done

describe 'zip', ->
  it 'zips streams', (done)->
    first = Jnoid.sequentially(10, [1, 2])
    second = Jnoid.sequentially(15, [100, 200])
    h.expectValues [[1, 100], [2, 100], [2, 200]],
      Jnoid.zip([first, second]),
      done

describe 'zipWith', ->
  it 'zips with function', (done)->
    first = Jnoid.sequentially(10, [1, 2])
    second = Jnoid.sequentially(15, [100, 200])
    h.expectValues [101, 102, 202],
      Jnoid.zipWith([first, second], (x, y) -> x + y),
      done

describe 'and', ->
  it 'executes boolean "and" between streams', (done)->
    first = Jnoid.sequentially(10, [false, true])
    second = Jnoid.sequentially(15, [false, true])
    h.expectValues [false, false, true],
      first.and(second),
      done

describe 'or', ->
  it 'executes boolean "or" between streams', (done)->
    first = Jnoid.sequentially(10, [false, true])
    second = Jnoid.sequentially(15, [false, true])
    h.expectValues [false, true, true],
      first.or(second),
      done

describe 'not', ->
  it 'executes boolean "not" on stream', (done)->
    stream = Jnoid.fromList([false, true, false])
    h.expectValues [true, false, true],
      stream.not(),
      done

describe 'filter', ->
  it 'filters stream', (done)->
    stream = Jnoid.fromList([10, 100, 20])
    h.expectValues [10, 20],
      stream.filter((x)-> x < 50),
      done

describe 'take', ->
  it 'takes n', (done)->
    stream = Jnoid.fromList([10, 100, 20, 200])
    h.expectValues [10, 100],
      stream.take(2),
      done

describe 'takeWhile', ->
  it 'takes while', (done)->
    stream = Jnoid.fromList([10, 100, 20])
    h.expectValues [10],
      stream.takeWhile((x)-> x < 50),
      done

describe 'prepend', ->
  it 'prepends a value to a stream', (done)->
    stream = Jnoid.fromList([10, 20, 30])
    h.expectValues [1, 10, 20, 30],
      stream.prepend(1),
      done

describe 'takeUntil', ->
  it 'takes until other stream pops', (done)->
    stream = Jnoid.sequentially(10, [10, 20, 30, 40, 50])
    stopper = Jnoid.later(35, 100)
    h.expectValues [10, 20, 30],
      stream.takeUntil(stopper),
      done

describe 'sequentially', ->
  it 'sends all events', (done)->
    h.expectValues [1, 2, 3],
      Jnoid.sequentially(10, [1, 2, 3]),
      done

describe 'later', ->
  it 'sends one event', (done)->
    h.expectValues [1],
      Jnoid.later(10, 1),
      done
