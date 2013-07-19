require 'coffee-script'
assert = require('chai').assert
h = require('./test_helpers')
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
    h.expectEvents [1, 2, 3],
      Jnoid.fromList([1, 2, 3]),
      done

describe 'unit', ->
  it 'sends a single event', (done)->
    h.expectEvents [1],
      Jnoid.unit(1),
      done

  it 'does not send anything with no arguments', (done)->
    h.expectEvents [],
      Jnoid.unit(),
      done

describe 'sequentially', ->
  it 'sends all events', (done)->
    h.expectEvents [1, 2, 3],
      Jnoid.sequentially(10, [1, 2, 3]),
      done

describe 'later', ->
  it 'sends one event', (done)->
    h.expectEvents [1],
      Jnoid.later(10, 1),
      done

describe 'flatMap', ->
  it 'combines spawned streams (trivial case)', (done)->
    stream = Jnoid.fromList([1, 2, 3])
    h.expectEvents [1, 2, 3],
      stream.flatMap((x)-> Jnoid.unit(x)),
      done

  it 'can be aliased as bind', (done)->
    stream = Jnoid.fromList([1, 2, 3])
    h.expectEvents [1, 2, 3],
      stream.bind((x)-> Jnoid.unit(x)),
      done

describe 'map', ->
  it 'transforms values', (done)->
    stream = Jnoid.fromList([1, 2, 3])
    h.expectEvents [2, 4, 6],
      stream.map((x)-> x * 2),
      done

describe 'merge', ->
  it 'merges lots of streams', (done)->
    first = Jnoid.fromList([1, 2, 3])
    second = Jnoid.fromList([10, 20, 30])
    third = Jnoid.fromList([100, 200, 300])
    h.expectEvents [1, 2, 3, 10, 20, 30, 100, 200, 300],
      first.merge(second, third),
      done

describe 'delay', ->
  it 'sends all events after a delay', (done)->
    first = Jnoid.fromList([1, 2, 3]).delay(10)
    second = Jnoid.fromList([10, 20, 30])
    h.expectEvents [10, 20, 30, 1, 2, 3],
      first.merge(second),
      done

describe 'zip', ->
  it 'zips streams', (done)->
    first = Jnoid.sequentially(10, [1, 2])
    second = Jnoid.sequentially(15, [100, 200])
    h.expectEvents [[1, 100], [2, 100], [2, 200]],
      first.zip(second),
      done

describe 'zipWith', ->
  it 'zips with function', (done)->
    first = Jnoid.sequentially(10, [1, 2])
    second = Jnoid.sequentially(15, [100, 200])
    h.expectEvents [101, 102, 202],
      first.zipWith(second, (x, y) -> x + y),
      done

describe 'and', ->
  it 'executes boolean "and" between streams', (done)->
    first = Jnoid.sequentially(10, [false, true])
    second = Jnoid.sequentially(15, [false, true])
    h.expectEvents [false, false, true],
      first.and(second),
      done

describe 'or', ->
  it 'executes boolean "or" between streams', (done)->
    first = Jnoid.sequentially(10, [false, true])
    second = Jnoid.sequentially(15, [false, true])
    h.expectEvents [false, true, true],
      first.or(second),
      done

describe 'not', ->
  it 'executes boolean "not" on stream', (done)->
    stream = Jnoid.fromList([false, true, false])
    h.expectEvents [true, false, true],
      stream.not(),
      done

describe 'filter', ->
  it 'filters stream', (done)->
    stream = Jnoid.fromList([10, 100, 20])
    h.expectEvents [10, 20],
      stream.filter((x)-> x < 50),
      done

describe 'takeWhile', ->
  it 'takes while', (done)->
    stream = Jnoid.fromList([10, 100, 20])
    h.expectEvents [10],
      stream.takeWhile((x)-> x < 50),
      done

describe 'onlyEnd', ->
  it 'only passes end', (done)->
    stream = Jnoid.fromList([10, 100, 20])
    h.expectEvents [],
      stream.onlyEnd(),
      done


describe 'prepend', ->
  it 'prepends a value to a stream', (done)->
    stream = Jnoid.fromList([10, 20, 30])
    h.expectEvents [1, 10, 20, 30],
      stream.prepend(1),
      done

describe 'takeUntil', ->
  it 'takes until other stream ends', (done)->
    stream = Jnoid.sequentially(10, [10, 20, 30, 40, 50])
    stopper = Jnoid.sequentially(35, [100])
    h.expectEvents [10, 20, 30],
      stream.takeUntil(stopper),
      done
