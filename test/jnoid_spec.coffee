assert = require('chai').assert
h = require('./test_helpers')
Jnoid = require '../jnoid.coffee.md'
{Event, Value, Error, End, Signal} = Jnoid

describe 'more and noMore', ->
  it 'is the same', ->
    assert.equal(Signal.more, Signal.more)
    assert.equal(Signal.noMore, Signal.noMore)

  it 'is different', ->
    assert.notEqual(Signal.more, Signal.noMore)


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
      Signal.fromList([1, 2, 3]),
      done

describe 'unit', ->
  it 'sends a single event', (done)->
    h.expectValues [1],
      Signal.unit(1),
      done

  it 'does not send anything with no arguments', (done)->
    h.expectValues [],
      Signal.unit(),
      done

describe 'onValue', ->
  it 'listens to values only', ->
    stream = new Signal (sink)->
      sink new Value 5
      sink new Error 'whut'
      sink new Value 10
      sink new End

    events = []
    stream.onValue (e)-> events.push e
    setTimeout ->
      assert.equal [5, 10], events
    , 1000

describe 'onError', ->
  it 'listens to values only', ->
    stream = new Signal (sink)->
      sink new Value 5
      sink new Error 'whut'
      sink new Value 10
      sink new End

    events = []
    stream.onError (e)-> events.push e
    setTimeout ->
      assert.equal ['whut'], events
    , 1000

describe 'map', ->
  it 'transforms values', (done)->
    stream = Signal.fromList([1, 2, 3])
    h.expectValues [2, 4, 6],
      stream.map((x)-> x * 2),
      done

describe 'filter', ->
  it 'filters stream', (done)->
    stream = Signal.fromList([10, 100, 20])
    h.expectValues [10, 20],
      stream.filter((x)-> x < 50),
      done

describe 'errors', ->
  it 'returns only errors', (done)->
    stream = new Signal (sink)->
      sink new Value 50
      sink new Error 'whut'
      sink new Value 100
      sink new End

    h.expectErrors ['whut'], stream.errors(), done

describe 'values', ->
  it 'returns only values', (done)->
    stream = new Signal (sink)->
      sink new Value 5
      sink new Error 'whut'
      sink new Value 10
      sink new End

    h.expectValues [5, 10], stream.values(), done

describe 'recover', ->
  it 'maps errors to values', (done)->
    stream = new Signal (sink)->
      sink new Value 5
      sink new Error 'whut'
      sink new Value 10
      sink new End

    h.expectValues [5, 4, 10],
      stream.recover((x) -> x.length),
      done

describe 'takeWhile', ->
  it 'takes while', (done)->
    stream = Signal.fromList([10, 100, 20])
    h.expectValues [10],
      stream.takeWhile((x)-> x < 50),
      done

describe 'take', ->
  it 'takes n', (done)->
    stream = Signal.fromList([10, 100, 20, 200])
    h.expectValues [10, 100],
      stream.take(2),
      done

describe 'skipDuplicates', ->
  it 'skips duplicates', (done)->
    stream = Signal.fromList([10, 10, 200, 200])
    h.expectValues [10, 200],
      stream.skipDuplicates(),
      done

describe 'flatMap', ->
  it 'combines spawned streams (trivial case)', (done)->
    stream = Signal.fromList([1, 2, 3])
    h.expectValues [1, 2, 3],
      stream.flatMap((x)-> Signal.unit(x)),
      done

describe 'merge', ->
  it 'merges lots of streams', (done)->
    first = Signal.fromList([1, 2, 3])
    second = Signal.fromList([10, 20, 30])
    third = Signal.fromList([100, 200, 300])
    h.expectValues [1, 2, 3, 10, 20, 30, 100, 200, 300],
      first.merge(second, third),
      done

describe 'zip', ->
  it 'zips streams', (done)->
    first = Signal.sequentially(10, [1, 2])
    second = Signal.sequentially(15, [100, 200, 300])
    h.expectValues [[1, 100], [2, 100], [2, 200], [2, 300]],
      Signal.zip([first, second]),
      done

describe 'zipWith', ->
  it 'zips with function', (done)->
    first = Signal.sequentially(10, [1, 2])
    second = Signal.sequentially(15, [100, 200, 300])
    h.expectValues [101, 102, 202, 302],
      Signal.zipWith([first, second], (x, y) -> x + y),
      done

describe 'zipAndStop', ->
  it 'zips streams and stops on first end', (done)->
    first = Signal.sequentially(10, [1, 2])
    second = Signal.sequentially(15, [100, 200, 300])
    h.expectValues [[1, 100], [2, 100]],
      Signal.zipAndStop([first, second]),
      done

describe 'zipWithAndStop', ->
  it 'zips with function and stops on first end', (done)->
    first = Signal.sequentially(10, [1, 2])
    second = Signal.sequentially(15, [100, 200, 300])
    h.expectValues [101, 102],
      Signal.zipWithAndStop([first, second], (x, y) -> x + y),
      done

describe 'and', ->
  it 'executes boolean "and" between streams', (done)->
    first = Signal.sequentially(10, [false, true])
    second = Signal.sequentially(15, [false, true])
    h.expectValues [false, false, true],
      first.and(second),
      done

describe 'or', ->
  it 'executes boolean "or" between streams', (done)->
    first = Signal.sequentially(10, [false, true])
    second = Signal.sequentially(15, [false, true])
    h.expectValues [false, true, true],
      first.or(second),
      done

describe 'not', ->
  it 'executes boolean "not" on stream', (done)->
    stream = Signal.fromList([false, true, false])
    h.expectValues [true, false, true],
      stream.not(),
      done

describe 'prepend', ->
  it 'prepends a value to a stream', (done)->
    stream = Signal.fromList([10, 20, 30])
    h.expectValues [1, 10, 20, 30],
      stream.prepend(1),
      done

describe 'takeUntil', ->
  it 'takes until other stream pops', (done)->
    stream = Signal.sequentially(10, [10, 20, 30, 40, 50])
    stopper = Signal.later(35, 100)
    h.expectValues [10, 20, 30],
      stream.takeUntil(stopper),
      done
