Jnoid
=====

This is a functional reactive programming library in Coffescript to use in
browser or Node.js applications. It owes the idea to Bacon.js, but should
describe the domain in proper terms, have less operations in primitives and be
shorter and simpler.

    Jnoid = {
      VERSION: "0.0.1"
    }

The core idea is having an abstraction of `Stream` which is a discrete
sequence of values and an abstraction of a `Box` which is a continous
time-varying value, both of which you can subscribe on.

Maybe and Events
----------------

We'll slightly extend the famous `Maybe` idiom to support error values. Now
it's a sum of `Maybe` and `Either` and can be described as `Maybe = Just x |
Wrong y | Nothing`.

    class Maybe

    class Just extends Maybe
      constructor: (@value) ->
      getOrElse: -> @value
      filter: (f) -> if @test(f) then @ else Nothing
      test: (f) -> f @value
      map: (f) -> new Just(f @value)
      isEmpty: -> false
      inspect: -> "Just #{@value}"

    class Bad extends Maybe
      getOrElse: (some)-> some
      filter: (f) -> @
      test: (f) -> true
      map: (f) -> @
      isEmpty: -> true

    class Wrong extends Bad
      constructor: (@error) ->
      inspect: -> "Wrong #{@error}"

    Nothing = new class extends Bad
      constructor: ->
      inspect: -> "Nothing"

`Event` class will be just a type alias for it.

    [Event, Fire, Error, Stop] = [Maybe, Just, Wrong, Nothing]
    toEvent = (x) -> if x instanceof Event then x else new Fire x
    toError = (x) -> if x instanceof Event then x else new Error x

Observable
----------

The point is that we can abstract from `Stream` and `Box` and define a common
behavior, calling it `Observable`.

Class `Observable` will be determined via a `subscribe` function. This
function should receive a subscriber or sink function as an argument and
call it whenever event is fired. This enables push semantics for `Stream`
and `Box`.

There are two ways to unsubscribe. First is to call function that subscribe
returns. Second is return `Reply.stop` from event listener.

    class Observable
      constructor: (subscribe)->
        @subscribe = @dispatched subscribe

`dispathed` is a function that makes `Observable` abstract and will hold the
actual implementation differences between `Stream` and `Box`. If you are
interested in `dispatched`, check it's implementations there.

      dispatched: fail

A basic ways to listen to Observable are `onValue` and `onError`. While
`subscribe` sends raw events, `onValue` unwraps them in case they hold values
and deliver them to the subscriber.

      onValue: (f) ->
        @subscribe (event) ->
          event.map((v)-> f(v)).getOrElse(Reply.more)

`onError` does roughly the same as `onValue`, but is selecting errors and
unwraps them.

      onError: (f) ->
        @subscribe (event) ->
          if event instanceof Error
            f event.error
          else
            Reply.more

We can now define basic transforms. Start with `map` and `filter`. We can
see common pattern there, it's abstracted in `withHandler`.

      withHandler: (handler)->
        new @constructor @dispatched(@subscribe, handler)

      map: (f)->
        @withHandler (event)-> @push event.map(f)

      filter: (f)->
        @withHandler (event)-> if event.test(f) then @push event else Reply.more

A useful combinator is `recover`, with will turn errors into regular
events using transform function.

      recover: (f)->
        @withHandler (event) ->
          if event instanceof Error
            @push new Fire f(event.error)
          else
            @push event

The most powerful combinator in our case is `flatMap`. It accepts a function
that turns each of the values in observable to a new observable. We then return
a new Observable that will combine them.

The first way to combine them is to just collect all the events from the
spawned childen. This matches the semantics of `Stream` and will allow us to
produce `merge`.

Another way to combine events is to unsubscribe all the existing children, when
a new event occurs on root, then spawn a new one and just listen to it. You can
think of it as swiching from one observable to another one. This matches the
semantics of `Box` and will allow us to produce `zip`.

      flatMapGeneric: (f, lastOnly) ->
        root = this
        new @constructor (sink) ->
          children = []
          rootStop = false
          unsubRoot = ->
          unsubChildren = ->
            unsubChild() for unsubChild in children
            children = []
          unbind = ->
            unsubChildren()
            unsubRoot()
          checkStop = ->
            if rootStop and (children.length == 0)
              sink Stop
          spawner = (event) ->
            if event == Stop
              rootStop = true
              checkStop()
            else
              unsubChildren() if lastOnly
              if event instanceof Error
                sink event
              else
                child = f event.value
                unsubChild = undefined
                childStopped = false
                removeChild = ->
                  remove(unsubChild, children) if unsubChild?
                  checkStop()
                handler = (event) ->
                  if event == Stop
                    removeChild()
                    childStopped = true
                    Reply.stop
                  else
                    tap sink(event), (reply)->
                      unbind() if reply == Reply.stop
                unsubChild = child.subscribe handler
                children.push unsubChild if not childStopped
          unsubRoot = root.subscribe(spawner)
          unbind

      flatMapAll: (f)-> @flatMapGeneric(f, false)
      flatMapLast: (f)-> @flatMapGeneric(f, true)

We can also define `skipDuplicates` which is extremely useful.

      withStateMachine: (initState, f) ->
        state = initState
        @withHandler (event) ->
          [newState, outputs] = f(state, event)
          state = newState
          stopped = any outputs,
                    (output)=> @push(output) == Reply.stop
          if stopped then Reply.stop else Reply.more

      skipDuplicates: (isEqual = (a, b) -> a is b) ->
        @withStateMachine Nothing, (prev, event) ->
          event.map((v)->
            if prev == Nothing || !prev.test((p)-> isEqual(v, p))
              [new Just(v), [event]]
            else
              [prev, []]
          ).getOrElse [prev, [event]]

From `withStateMachine` we can easily define `scan`:

      scan: (initState, f) ->
        @withStateMachine initState, (acc, event)->
          newAcc = event.map((v)->f(acc, v)).getOrElse(acc)
          [newAcc, [toEvent newAcc]]

Always good in UI there is an option to `debounce`:

      debounce: (delay)->
        @flatMapLast (value)=>
          @constructor.later delay, value

Let's do `take` and `takeWhile`:

      take: (n)->
        return @constructor.nothing() if n <= 0
        @withHandler (event) ->
          unless event instanceof Fire
            @push event
          else
            n--
            if n > 0
              @push event
            else
              @push event if n == 0
              @push Stop
              Reply.stop

      takeWhile: (f)->
        @withHandler (event) ->
          if event.test(f)
            @push event
          else
            @push Stop
            Reply.stop

`takeUntil` is going to be slightly more complicated - it's going to listen to
one stream till an event on another appears. A very useful one:

      takeUntil: (other)->
        source = this
        stopper = other.changes()
        new @constructor (sink)->
          unsubSource = ->
          unsubStopper = ->
          unbind = ->
            unsubSource()
            unsubStopper()

          transport = (event)->
            sink event
            unbind() if event == Stop
          watcher = (event)->
            sink Stop
            unbind()

          unsubSource = source.subscribe(transport)
          unsubStopper = stopper.subscribe(watcher)
          unbind

A helper method for boolean algebra (others are map2 based methods and so are
just applicable to box):

      not: -> @map (x)-> !x

How to build observables

------------------------

The basic ways to build an observable are `nothing`, `unit` and `error`. In
`Stream` semantics they mean `never`, `once` and `error`, in `Box` semantics
they mean `empty`, `always` and `error`. We won't create the aliases and give
these names to get you the feel of what they mean.

      @fromList: (values, wrapper = toEvent)->
        new @ (sink) ->
          sink event for event in map wrapper, values
          sink Stop

      @nothing: -> @fromList []
      @unit: (value)-> @fromList [value]
      @error: (value)-> @fromList [value], toError

`fromBinder` just adds a syntax sugar for us to easily define more
sophisticated constructors.

      @fromBinder: (binder, transform = id) ->
        new @ (sink) ->
          unbinder = binder (args...) ->
            events = toArray transform args...
            for event in map toEvent, events
              tap sink(event), (reply)->
                unbinder() if event == Stop or reply == Reply.stop

`poll` polls a function within given interval.

      @poll: (delay, poll) ->
        @fromBinder (handler) ->
          i = setInterval(handler, delay)
          -> clearInterval(i)
        , poll

`interval` and `later` send a fixed list of events or one event
respectively within given interval.

      @interval: (delay, list)->
        index = 0
        @poll delay, ->
          value = list[index++]
          if index < list.length
            value
          else if index == list.length
            [value, Stop]
          else
            Stop

      @later: (delay, value)->
        @interval(delay, [value])

Let's also define a function that works on promises, e.g., ajax. The
resource releasing here for ajax is abort. We should also handle promise
errors here. In a transform function we attach end to our stream.

      @fromPromise: (promise) ->
        @fromBinder (handler) ->
          promise.then handler, (e) ->
            handler new Error e
          -> promise.abort?()
        , (value) -> [value, Stop]

Finally let's define the way to receive events from DOM objects. We'll do
it assuming we're called in jQuery/Zepto fashion.

We allow to override `transform` - by default it'll take the first
argument, which is usually a jQuery event. We use `on` to subscribe and
`off` to unsubscribe.

      @fromDOM: (element, event, selector, transform) ->
        [transform, selector] = [selector, null] if isFunction(selector)

        @fromBinder (handler) =>
          element.on(event, selector, handler)
          => element.off(event, selector, handler)
        , transform


Stream
------

Class `Stream` represents a disrete sequence of values, coupled with time.  So
it uses the appropriate dispatcher to do it.

`Dispatcher` activates the listeners when a first sink is added and then just
adds them. On each event it just pushes it to all sinks.

    class StreamDispatcher
      constructor: (subscribe, handler) ->
        subscribe ?= (event) ->
        sinks = []
        @push = (event) =>
          indexes.unshift(i) for sink, i in sinks when sink(event) is Reply.stop if indexes = []
          sinks.splice(i,1) for i in indexes
        handler ?= (event) -> @push event
        @handler = (event) => handler.apply(this, [event])
        @subscribe = (sink) =>
          sinks.push(sink)
          unsubSelf = subscribe @handler if sinks.length == 1
          ->
            remove sink, sinks
            unsubSelf?() unless any sinks

To have `Stream` class we just need to override abstract `dispatched` method
from the base class to use `StreamDispatcher`.

    class Stream extends Observable
      dispatched: (subscribe, handler)->
        new StreamDispatcher(subscribe, handler).subscribe

For this class we can have `flatMap` aka `bind`. In our case it's `flatMapAll`.

      flatMap: (args...)-> @flatMapAll(args...)

Having this we can easily have `merge`.

      merge: (others...)->
        Stream.fromList(map method("changes"), [@, others...]).flatten()
      flatten: -> @flatMap(id)

Using Stream when we need Box
-----------------------------

To make it transparent for a user, is this stream or box, we proxy the box
methods to box. First we define a conversion method with an optional starting
value.

      box: (initial = Nothing)->
        initial = toMaybe(initial)
        new Box (sink)=>
          sink initial unless initial.isEmpty()
          @subscribe (event)-> sink event
      changes: -> @

We could also define a new stream with initial value merged to the beginning,
but the current code is simple enough.

All proxy methods are trivial.

      zipWith: (others..., f)-> @box().zipWith(others..., f)
      and: (others...)-> @box().and(others...)
      or: (others...)-> @box().or(others...)
      not: -> @box().not()

Box
---

Class `Box` represents continuous value that changes with time. So we need a
slightly tweaked dispatcher. The difference is that it holds the current
value and sends it to each new subscriber. Another difference is that even when
the Box is ended, it still sends the last value and then immediately sends stop

    class BoxDispatcher extends StreamDispatcher
      constructor: (subscribe, handler) ->
        super subscribe, handler
        current = Nothing
        push = @push
        subscribe = @subscribe
        stopped = false

        @push = (event) =>
          event.map((x) -> current = new Just x)
          stopped = true if event == Stop
          push.apply(this, [event])
        @subscribe = (sink) =>
          reply = current.map((v)-> sink new Fire v)
          if reply.getOrElse(Reply.more) == Reply.stop
            nop
          else if stopped
            sink Stop
            nop
          else
            subscribe.apply(@, [sink])

Now class `Box` is going to use that dispatcher.

    class Box extends Observable
      dispatched: (subscribe, handler)->
        new BoxDispatcher(subscribe, handler).subscribe

For this class we can have `flatMap` aka `bind`. In our case it's `flatMapLast`.

      flatMap: (args...)-> @flatMapLast(args...)

With this `flatMap` we can define a glorious `map2`, also known as `zipWith`
for two boxes.

      map2: (other, f)->
        @flatMap (x)-> other.box().map (y)-> f(x, y)

Having this, `zipWith` is easy.

      @sequence: (boxes)->
        foldl boxes, @unit([]), (acc, box)->
          acc.map2 box, (memo, value)-> append memo, value
      @zipWith: (boxes, f)->
        @sequence(boxes).map uncurry f
      zipWith: (others..., f)->
        Box.zipWith [@, others...], f

Helpful would be to define boolean algebra over boxes. `not` is defined on
`Observable`.

      and: (others...)-> @zipWith others..., (a, b)-> a && b
      or: (others...)-> @zipWith others..., (a, b)-> a || b

An interesting `sampledBy` function should take a property and stream it's
value when sampler pops:

      sampledBy: (sampler)->
        sampler.flatMap(=> @take(1)).changes()

Using Box when we need Stream
-----------------------------

To convert `Box` into `Stream` we take it's changes.

      changes: ->
        new Stream (sink)=>
          @subscribe (event)-> sink event
      box: -> @

Here are the proxy methods.

      merge: (others...)-> @changes().merge(others...)

Helpers
-------

Pretty trivial special values to return from event listeners.

    Reply =
      stop: "<stop>"
      more: "<more>"

We need some simple helper functions.

    empty = (xs)-> xs.length == 0
    method = (meth)-> (obj)-> obj[meth]()
    nop = ->
    id = (x)-> x
    fail = -> throw "method not implemented"
    head = (xs) -> xs[0]
    tail = (xs) -> xs[1...xs.length]
    uncurry = (f) -> (args)-> f(args...)
    map = (f, xs) -> f(x) for x in xs
    foldl = (xs, seed, f) ->
      for x in xs
        seed = f(seed, x)
      seed
    tap = (x, f) ->
      f(x)
      x
    remove = (x, xs) ->
      i = xs.indexOf(x)
      xs.splice(i, 1) if i >= 0
    all = (xs, f = id) ->
      for x in xs
        return false if not f(x)
      return true
    any = (xs, f = id) ->
      for x in xs
        return true if f(x)
      return false
    copyArray = (xs)-> xs.slice()
    append = (xs, x)-> tap copyArray(xs), (copy)-> copy.push x
    isFunction = (f) -> typeof f == "function"
    toArray = (x) -> if x instanceof Array then x else [x]
    toMaybe = (x) ->
      if x instanceof Maybe then x else new Just x

Exports
-------

We now need to make our objects usable outside.

    for name, value of {Stream, Box, Event, Fire, Error, Stop,
                                     Maybe, Just, Wrong, Nothing}
      Jnoid[name] = value

    if define?.amd
      define [], -> Jnoid
    else if module?.exports
      module.exports = Jnoid
    else
      @Jnoid = Jnoid

Conclusion
----------

Have fun!
