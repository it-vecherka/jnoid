assert = require('chai').assert
h = require('./test_helpers')
{Stream, Box, Event, Fire, Error, Stop} = require '../jnoid'

describe 'EventStream', ->
  describe 'basics', ->
    it 'creates simple sequential stream', (done)->
      h.expectValues [1, 2, 3],
        Stream.interval(10, [1, 2, 3]),
        done

    it 'can be subscribed twice', (done)->
      i = 0
      donner = -> done() if ++i >= 2
      stream = Stream.interval(10, [1, 2, 3])
      h.expectValues [1, 2, 3], stream, donner
      setTimeout((-> h.expectValues([2, 3], stream, donner)), 15)

  describe 'unit', ->
    it 'nothing creates empty stream', (done)->
      h.expectValues [], Stream.nothing(), done

    it 'unit creates simple stream', (done)->
      h.expectValues [5], Stream.unit(5), done

  describe 'transformation', ->
    it 'map maps events', (done)->
      h.expectValues [10, 20, 30],
        Stream.interval(10, [1, 2, 3]).map((x)-> x*10),
        done

    it 'tap applies function, but keeps events', (done)->
      arr = [1, 2, 3]
      donner = ->
        assert.deepEqual arr, [1, 2, 3, 4]
        done()
      h.expectValues [arr],
        Stream.later(10, arr).tap((x)-> x.push(4)),
        donner

    it 'filter filters events', (done)->
      h.expectValues [1, 3],
        Stream.interval(10, [1, 2, 3]).filter((x)-> x % 2 != 0 ),
        done

    it 'flatMap collects all the values from spawned streams', (done)->
      stream = Stream.interval(10, [1, 2, 3])
      h.expectValues [10, 100, 20, 200, 30, 300],
        stream.flatMap((x)-> Stream.interval(8, [10*x, 100*x])),
        done

    it 'skipDuplicates skips duplicates', (done)->
      stream = Stream.interval(5, [10, 10, 200, 200])
      h.expectValues [10, 200],
        stream.skipDuplicates(),
        done

  describe 'listener', ->
    it 'onValue listens to values only', ->
      stream = new Stream (sink)->
        sink new Fire 5
        sink new Error 'whut'
        sink new Fire 10
        sink Stop

      events = []
      stream.onValue (e)-> events.push e
      setTimeout ->
        assert.equal [5, 10], events
      , 1000

    it 'onError listens to errors only', ->
      stream = new Stream (sink)->
        sink new Fire 5
        sink new Error 'whut'
        sink new Fire 10
        sink Stop

      events = []
      stream.onError (e)-> events.push e
      setTimeout ->
        assert.equal ['whut'], events
      , 1000

    it 'activate activates stream and returns self', ->
      stream = Stream.interval(10, [1, 2, 3]).activate()
      events = []
      setTimeout ->
        stream.onValue (e)-> events.push e
        setTimeout ->
          assert.deepEqual [2, 3], events
        , 1000
      , 15

  describe 'recover', ->
    it 'maps errors to values', (done)->
      stream = new Stream (sink)->
        sink new Fire 5
        sink new Error 'whut'
        sink new Fire 10
        sink Stop

      h.expectValues [5, 4, 10],
        stream.recover((x) -> x.length),
        done

  describe 'combination', ->
    it 'merge merges streams', (done)->
      first = Stream.interval(5, [1, 2])
      second = Stream.interval(15, [10, 20])
      h.expectValues [1, 2, 10, 20],
        first.merge(second),
        done

  describe 'take', ->
    it 'takes n values', (done)->
      stream = Stream.interval(5, [1, 2, 3, 4, 5])
      h.expectValues [1, 2, 3],
        stream.take(3)
        done

  describe 'takeUntil', ->
    it 'takes until another stream pops', (done)->
      first = Stream.interval(10, [1, 2, 3, 4, 5])
      second = Stream.later(35, 'anything')
      h.expectValues [1, 2, 3],
        first.takeUntil(second),
        done

  describe 'takeWhile', ->
    it 'takes while predicate', (done)->
      stream = Stream.interval(5, [1, 11, 2, 3, 4, 5])
      h.expectValues [1, 11],
        stream.takeWhile((x)->x%2==1),
        done

  describe 'box', ->
    it 'tranforms stream into box', (done)->
      stream = Stream.interval(10, [1, 2])
      box = stream.box()
      assert.instanceOf box, Box
      h.expectValues [1, 2],
        box,
        done

    it 'optionally appends initial value', (done)->
      stream = Stream.interval(10, [1, 2])
      box = stream.box(100)
      assert.instanceOf box, Box
      h.expectValues [100, 1, 2],
        box,
        done

describe "Box", ->
  describe "essence", ->
    it "streams current value", (done)->
      i = 0
      donner = -> done() if ++i >= 2
      box = Box.interval(10, [1, 2, 3])
      h.expectValues [1, 2, 3], box, donner
      setTimeout((-> h.expectValues([1, 2, 3], box, donner)), 15)

    it "streams ended value", (done)->
      i = 0
      donner = -> done() if ++i >= 2
      box = Box.interval(10, [1, 2])
      h.expectValues [1, 2], box, donner
      setTimeout((-> h.expectValues([2], box, donner)), 25)

  describe "specific", ->
    it 'flatMap collects only the values from last spawned streams', (done)->
      stream = Box.interval(10, [1, 2, 3])
      h.expectValues [10, 20, 30, 300],
        stream.flatMap((x)-> Box.interval(8, [10*x, 100*x])),
        done

    it "map2 zips two boxes", (done)->
      first = Box.interval(10, [1, 2])
      second = Box.interval(15, [100, 200, 300])
      h.expectValues [102, 202, 302],
        first.map2(second, (x, y) -> x + y),
        done

    it "sequence turns a list of boxes into a box of lists", (done)->
      first = Box.interval(10, [1, 2])
      second = Box.interval(15, [10, 20, 30])
      h.expectValues [[2, 10], [2, 20], [2, 30]],
        Box.sequence([first, second]),
        done

    describe 'zip', ->
      it 'with another stream', (done)->
        first = Box.interval(10, [1, 2])
        second = Box.interval(15, [5, 7, 9])
        h.expectValues [[2, 5], [2, 7], [2, 9]],
          first.zip(second),
          done

    describe 'zipWith', ->
      it 'zips with function', (done)->
        first = Box.interval(10, [1, 2])
        second = Box.interval(15, [100, 200, 300])
        h.expectValues [102, 202, 302],
          first.zipWith(second, (x, y) -> x + y),
          done

  describe 'boolean', ->
    it 'and executes boolean "and" between streams', (done)->
      first = Box.interval(10, [false, true])
      second = Box.interval(15, [false, true])
      h.expectValues [false, true],
        first.and(second),
        done

    it 'or executes boolean "or" between streams', (done)->
      first = Box.interval(10, [false, true])
      second = Box.interval(15, [false, true])
      h.expectValues [true, true],
        first.or(second),
        done

    it 'not executes boolean "not" on box', (done)->
      box = Box.interval(10, [false, true, false])
      h.expectValues [true, false, true],
        box.not(),
        done

  describe 'sampledBy', ->
    it 'samples box with a stream', (done)->
      stream = Stream.interval(10, [1, 2, 3, 4, 5])
      box = Stream.later(25, 2).box(1)
      h.expectValues [1, 1, 1, 2, 2],
        box.sampledBy(stream),
        done

  describe "changes", ->
    it "gets stream of changes from box", (done)->
      box = Box.interval(10, [1, 2])
      stream = box.changes()
      assert.instanceOf stream, Stream
      h.expectValues [1, 2],
        stream,
        done
