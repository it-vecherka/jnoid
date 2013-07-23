Jnoid
=====

Synopsis
--------

This source file itself is a [functional reactive
programming](http://en.wikipedia.org/wiki/Functional_reactive_programming)
library for web clients or nodejs applications. Most of it's concepts are
borrowed from [Bacon.js](https://github.com/raimohanska/bacon.js), but the
purpose is to give an insight on FRP paradigm and explain the approach in the
very code. This is why the code is written in [literate
programming](http://en.wikipedia.org/wiki/Literate_programming) style.

There are however another reasons for this library to exist. It's small,
simple, offers just one concept and aims to be fully usable nontheless.

The problem
-----------

The concept of the web has been changed and we now have to write rich,
featureful client-side interfaces. There are some binding frameworks for that
like Knockout or Backbone, and of cource they help a lot. However, their
abstractions have two problems in common:

* They are too implicit. Lots of things are done with bindings somewhere
outside.
* The abstractions they suggest are very poorly composable and tend to lead us
to the code repetition.

Instead we suggest Functional Reactive Programming.

The general idea is to have the abstraction for a *signal* that we can observe
and compose, so that we can constuct complex signals for the basic ones and
then bind the side-effect code that manipulates DOM to the events.

All our application logic should be in pure functions and only a ui related
code will be in IO functions. Complex stuff should be handled with this library
and isolated from pure logic.

All right, what do we do?
-------------------------

Let think of the primitives. The core will be `EventStream` abstraction
- a representation of the continous discrete events line. We're going then to
write some compositions for the streams and some ways to construct the streams
from various sources.

So at step zero we define the object we export. Let's call our library "Jnoid".

    Jnoid = {}

Events
------

At first we define the event wrapper we're going to use. Pretty straigtforward.

    class Event
      isEnd: -> false
      isValue: -> false
      isError: -> false
      filter: -> true
      fmap: -> @

That was the base class, now we define the classes we're actually going to use.
`Value` class is going to represent the most usual event we'll send.

    class Value extends Event
      constructor: (@value) ->
      isValue: -> true
      describe: -> @value
      inspect: -> "Event.Value<#{@value}>"

This class is going to be used like a functor so we define a couple of helper
functions in it.

      filter: (f)-> f @value
      fmap: (f)-> new Value f @value

`Error` class is going to represent an important case where in some stream an
error pops out. This will have to be correctly composed in our combinators.

    class Error extends Event
      constructor: (@error) ->
      isError: -> true
      describe: -> "<error> #{@error}"
      inspect: -> "Event.Error<#{@error}>"

`End` is a special case for the stream end. We could define it as a singleton,
but let's be simple for a while for the stream end.

    class End extends Event
      constructor: ->
      isEnd: -> true
      test: -> true
      describe: -> '<end>'
      inspect: -> "Event.End"

A handy function can be:

    toEvent = (x) -> if x instanceof Event then x else new Value x

Now let's think about the `EventStream` class. How it's going to be
represented?

EventStream
-----------

The core behaviour of the `EventStream` we define with a function we call
`unfold` which is provided to the constructor. This `unfold` function itself is
a function that accepts a function, `subscriber`, that will receive Events.
`unfold` will get the events and pass it to the `subscriber` function.

Let think in advance of termination. Let the `unfold` function to return a
function (it's FP, dude!) that, when called, will do the unsubscribing, which
will release all the resources captured.

An altertative way will be that if a `subscriber`, and that's the only function
we've yet discussed that will be written in application code, to return some
special value, and if it does, we will also do the unsubscribe. By the way, we
need to define these special value. Let's be simple:

    Jnoid.more = "<more>"
    Jnoid.noMore = "<no more>"

Let's also at once define a poller that asserts if we're given
`Jnoid.noMore`: 

    tapUnsub = (reply, unsub)->
      unsub() if reply == Jnoid.noMore
      reply

We could define it via K-combinator, but it would be even
more code.

Now finally:

    class EventStream
      constructor: (unfold) ->
        @unfold = new Dispatcher(unfold).unfold

If `unfold` scares someone, for the outer application code it may be thought as
`subscribe`.

        @subscribe = @unfold

### What's that dispatcher?

An abstraction that is complex and dirty. It'll store all of the subscribers and
propagate the evens popped from `unfold` we passed to it to all of them. It'll
also maintain the unsubscribe logic. We're going to define it later.

Trivial constructors
--------------------

Let's say we want to send just a list of events. What do we do?

      @fromList = (list)->
        new EventStream (sink)->
          sink (toEvent value) for value in list
          sink (new End)
          nop

`nop` is a function that does nothing. We'll define this obvious helper
functions later.

Now let's define the varargs version of `EventStream.fromList`.

      @unit = (args...)-> @fromList(args)

An interesting thing about `EventStream.unit` is that if it's called with one
(or no) arguments, it conforms with a
[monadic](http://en.wikipedia.org/wiki/Monad_(functional_programming) concept
of unit. If we later define bind, and they will conform monadic laws,
`EventStream` will become a monad. It's FP, dude!

### Logging

This trivial `EventStream` function will help us a lot:

      log: (args...) ->
        @subscribe (event) -> console?.log?(args..., event.describe())
        this

Accessing
---------

`unfold`/`subscribe` are nesessary but raw, as they pass the event class, not
it's value. Let's define more convenient access to the stream.

      onValue: (f) ->
        @subscribe (event) -> if event.isValue() then f(event.value) else Jnoid.more

      onError: (f) ->
        @subscribe (event) -> if event.isError() then f(event.error) else Jnoid.more

Transformers
------------

Let's give a way to transform the output. The most basic combinators are
`map` and `filter`.  Combinator `map` transforms the values of events,
while `filter` filters the events based on their values.

Recall how we carefully declared `fmap` and `filter` in `Event` class. This way
our `map` and `filter` will only touch values and leave errors and end at they
are.

      withHandler: (handler) ->
        dispatcher = new Dispatcher(@unfold, handler)
        new EventStream(dispatcher.unfold)

      map: (f) ->
        @withHandler (event) -> @push event.fmap(f)

      filter: (f) ->
        @withHandler (event) -> if event.filter(f) then @push event else Jnoid.more

We can now receive only non-value events this way:

      errors: -> @filter -> false

To have values, however, we'll have to define a custom function:

      values: ->
        @withHandler (event) -> unless event.isError() then @push event else Jnoid.more

Let's also declare `recover` that will map errors into values using
transform function.

      recover: (f)->
        @withHandler (event) ->
          if event.isError()
            @push new Value f event.error
          else
            @push event

Another handy function is transit a stream to a stopper. On any event it'll
just stop.

      toStopper: ->
        @withHandler (event) ->
          @push new End
          Jnoid.noMore

As a slightly more fun stuff, here's `takeWhile`. It takes values from stream
while assering their values with a given function remains true.

      takeWhile: (f) ->
        @withHandler (event) ->
          if event.filter(f)
            @push event
          else
            @push new End
            Jnoid.noMore

We may also want `take` that just takes `n` events from stream.

      take: (count) ->
        return Jnoid.unit() if count <= 0
        @withHandler (event) ->
          if event.filter(-> false)
            @push event
          else
            count--
            if count > 0
              @push event
            else
              @push event if count == 0
              @push new End
              Jnoid.noMore

We can even do fancier stuff. Let's define `withStateMachine` that
remembers previous value and can take decisions based on it:

      withStateMachine: (initState, f) ->
        state = initState
        @withHandler (event) ->
          [newState, outputs] = f(state, event)
          state = newState
          reply = Jnoid.more
          for output in outputs
            reply = @push output
            return reply if reply == Jnoid.noMore
          reply

With this for example we can have `skipDuplicates` which is extremely
useful.

      skipDuplicates: (isEqual = (a, b) -> a is b) ->
        @withStateMachine undefined, (prev, event) ->
          if event.filter(-> false)
            [prev, [event]]
          else if prev == undefined or not isEqual(prev, event.value)
            [event.value, [event]]
          else
            [prev, []]

flatMap
-------

It's time to become more powerful. In functional programming, `map` is not the
basic combinator. The basic is a really powerful `flatMap`. Let's think what
it's going to do in our case.

`map` receives a function that transforms event value to another value. A more
general approach is that we take each value in a stream and start a stream with
it. So the function we pass there will create a new stream based on a value.
Afterwards we join all the streams collecting values from all of them.

It's going to be a complex stuff. It has to listen to the source stream and
spawn the streams, joining their unfolds. It'll also have to terminate
properly. The 'and' conditions of termination of the resulting stream is:

* Source has ended.
* All of the children have ended.

It's going to be huge and not so pretty. Don't worry about it. We'll do
such things only one more time.

      flatMap: (f) ->
        root = this
        new EventStream (sink) ->
          children = []
          rootEnd = false
          unsubRoot = ->
          unbind = ->
            unsubRoot()
            unsubChild() for unsubChild in children
            children = []
          checkEnd = ->
            if rootEnd and (children.length == 0)
              sink new End
          spawner = (event) ->
            if event.isEnd()
              rootEnd = true
              checkEnd()
            else if event.isError()
              sink event
            else
              child = f event.value
              unsubChild = undefined
              childEnded = false
              removeChild = ->
                remove(unsubChild, children) if unsubChild?
                checkEnd()
              handler = (event) ->
                if event.isEnd()
                  removeChild()
                  childEnded = true
                  Jnoid.noMore
                else
                  tapUnsub sink(event), unbind
              unsubChild = child.unfold handler
              children.push unsubChild if not childEnded
          unsubRoot = root.unfold(spawner)
          unbind

By the way, this was the most tricky part to make EventStream kind of a monad
(controversial as always). In a Haskell world this function is usually called
`bind`, let's make an alias:

      bind: (args...)-> @flatMap(args...)

This combinator gives us lots of power. Imagine at first place that we want
to merge streams. It's unbelievably simple ( `id` is a function that
returns it's first argument).

      merge: (others...)-> EventStream.fromList([@, others...]).join()
      join: -> @flatMap(id)

Join transforms stream of streams into just a stream, so another common
name for it is flatten.

      flatten: -> @join()

Another example is that we can easily implement a delay.

      delay: (delay)-> @flatMap (x)-> Jnoid.later(delay, x)

We know we haven't defined `Jnoid.later` yet with all similar fancy
constructors, but it's obvious - something that takes a value and returns a
stream that pops this value in a given amount of time, then ends.

For fun, note that we could define `map` as:

      collect: (f)-> @flatMap (x)-> EventStream.unit(f(x))

Zip
---

But that's not all the power we need. We also need to zip streams. Zipping is
turning a list of streams to a stream that on value in any of them sends the
tuple of all their latest values. It can terminate when all the streams ended
or when any of the streams ended - those'll serve different purposes.

Again as with the `flatMap` it'll be fat, ugly and operate mutable state.
But you don't have to worry about it as long as your code will be pure.

These functions do not have the main stream so we define them as class
functions:

      @zip: (streams, endChecker = all) ->
        if streams.length
          values = (undefined for s in streams)
          new EventStream (sink) =>
            unsubscribed = false
            unsubs = (nop for s in streams)
            unsubAll = (-> f() for f in unsubs ; unsubscribed = true)
            ends = (false for s in streams)
            checkEnd = ->
              if endChecker(ends)
                tapUnsub sink(new End()), unsubAll
            combiningSink = (markEnd, setValue) ->
              (event) ->
                if (event.isEnd())
                  markEnd()
                  checkEnd()
                  Jnoid.noMore
                else if event.isError()
                  tapUnsub sink(event), unsubAll
                else
                  setValue(event.value)
                  if all(values, (x) -> x != undefined)
                    tapUnsub sink(toEvent map(id, values)), unsubAll
                  else
                    Jnoid.more
            sinkFor = (index) ->
              combiningSink(
                (-> ends[index] = true)
                ((x) -> values[index] = x)
              )
            for stream, index in streams
              unsubs[index] = stream.unfold (sinkFor index) unless unsubscribed
            unsubAll
        else
          EventStream.unit([])

      @zipAndStop: (streams)-> @zip(streams, any)

The combinators we've just done are unbelievably useful. Let's first expand
them to `zipWith` and `zipWithAndStop` to see it.

      @zipWith: (streams, f)-> @zip(streams).map(uncurry(f))
      @zipWithAndStop: (streams, f)-> @zipAndStop(streams).map(uncurry(f))

Let's proxy this useful stuff to instance methods:

      zip: (others...)-> EventStream.zip [@, others...]
      zipWith: (others..., f)-> EventStream.zipWith [@, others...], f
      zipAndStop: (others...)-> EventStream.zipAndStop [@, others...]
      zipWithAndStop: (others..., f)-> EventStream.zipWithAndStop [@, others...], f

Now let's go and define boolean algebra over our streams:

      and: (others...)-> EventStream.zipWith [@, others...], (a, b)-> a && b
      or: (others...)-> EventStream.zipWith [@, others...], (a, b)-> a || b
      not: -> @map (x)-> !x

Feel the power? Let's do a complex stuff. Combine two streams so that we pop
the first stream until we have a value on the second stream.

      prepend: (x)-> EventStream.unit(x).merge(@)
      takeUntil: (stopper) ->
        EventStream.zipWithAndStop [@, stopper.toStopper().prepend(1)], left

Having `takeUntil` we can do a sophisticated `flatMapLatest`. It'll create a
steam that joins all the streams created with a spawner function, but in a
different way. It'll take only the values from the latest stream spawned.

      flatMapLatest: (f) -> @flatMap (x) => f(x).takeUntil(@)

Let's combine it with `later` to implement a classic `debounce`:

      debounce: (delay) ->
        @flatMapLatest (value) ->
          Jnoid.later delay, value

Take a break. Think of all the power we got. Now we want to create these
streams from everything.

Constructors
------------

Stop here and think about the basic pattern. New EventStream is defined via
`unfold` function and we've already negotiated about the rules about it. Let's
attempt to formalize these rules so that we'll only have to specify the
behaviour.

Here binder is the stuff that is going to pop out events and transform is a
handy way to handle them. Transform is allowed to return an array of events and
all of them will be popped out to subscriber.

      @fromBinder: (binder, transform = id) ->
        new EventStream (sink) ->
          unbinder = binder (args...) ->
            events = toArray transform args...
            for e in events
              event = toEvent e
              tap sink(event), (reply)->
                unbinder() if reply == Jnoid.noMore or event.isEnd()

We're going to expose `Jnoid` variable so the complex way of constructing
streams we'll place there. Let's first proxy the basics.

    Jnoid.unit = EventStream.unit
    Jnoid.fromList = EventStream.fromList
    Jnoid.fromBinder = EventStream.fromBinder

By the way, let's also copy our useful combinators.

    Jnoid.zip = EventStream.zip
    Jnoid.zipWith = EventStream.zipWith
    Jnoid.zipAndStop = EventStream.zipAndStop
    Jnoid.zipWithAndStop = EventStream.zipWithAndStop

Let's use our binder to get aquainted. We want to create a stream that will
poll some io function with a given interval. To recall, we should return a
function that will release the resources, so we return `clearInterval`.


    Jnoid.fromPoll = (delay, poll) ->
      Jnoid.fromBinder (handler) ->
        i = setInterval(handler, delay)
        -> clearInterval(i)
      , poll

With this we can easily define `Jnoid.later` we've been using in delay.

    Jnoid.sequentially = (delay, list)->
      index = 0
      Jnoid.fromPoll delay,->
        value = list[index++]
        if index < list.length
          value
        else if index == list.length
          [value, new End]
        else
          new End

    Jnoid.later = (delay, value)->
      Jnoid.sequentially(delay, [value])

Let's also define a function that works on promises, e.g., ajax. The
resource releasing here for ajax is `abort`. We should also handle promise
errors here. In a transform function we attach end to our stream. As we
hoped, transform helps us a lot.


    Jnoid.fromPromise = (promise) ->
      Jnoid.fromBinder (handler) ->
        promise.then handler, (e) -> handler new Error e
        -> promise.abort?()
      , (value) -> [value, new End]

Interesting that with `fromPromise` and things like `flatMap` we can do a
sophisticated thing: `promises()` stream transformer. It'll turn a stream
of some values into a stream of returned values from those promises. A
good example of `promise` you can pass to that function is `jQuery.ajax`.

    EventStream::promises = (promise)->
      @flatMapLatest (params)-> Jnoid.fromPromise promise params

Finally let's define the way to receive events from DOM objects. We'll do
it assuming we're called in jQuery/Zepto fashion.

We allow to override `transform` - by default it'll take the first
argument, which is usually a jQuery event. We use `on` to subscribe and
`off` to unsubscribe.

    Jnoid.fromDOM = (element, event, selector, transform) ->
      [eventTransformer, selector] = [selector, null] if isFunction(selector)

      Jnoid.fromBinder (handler) =>
        element.on(event, selector, handler)
        => element.off(event, selector, handler)
      , eventTransformer

Dispatcher
----------

All right, now let's write a dispatcher. We could use javascript events but
let's do it manually. After all, there is not so much code in it.

Yes, it stores mutable state, but it's not observable from code - it's just
observable from the real world. We're good.

    class Dispatcher
      constructor: (unfold, handleEvent) ->
        unfold ?= (event) ->
        sinks = []
        @push = (event) =>
          for sink in sinks
            tapUnsub sink(event), -> remove(sink, sinks)
          if (sinks.length > 0) then Jnoid.more else Jnoid.noMore
        handleEvent ?= (event) -> @push event
        @handleEvent = (event) => handleEvent.apply(this, [event])
        @unfold = (sink) =>
          sinks.push(sink)
          unsubSelf = unfold @handleEvent if sinks.length == 1
          ->
            remove(sink, sinks)
            unsubSelf?() unless any sinks

Boring stuff
------------

### Handy functions

There are a lot of trivial handy functions we've used above so here they are:

    nop = ->
    id = (x)-> x
    left = (x, y)-> x
    right = (x, y)-> y
    tap = (x, f) ->
      f(x)
      x
    empty = (xs) -> xs.length == 0
    head = (xs) -> xs[0]
    tail = (xs) -> xs[1...xs.length]
    uncurry = (f) -> (args)-> f(args...)
    map = (f, xs) ->
        f(x) for x in xs
    all = (xs, f = id) ->
      for x in xs
        return false if not f(x)
      return true
    any = (xs, f = id) ->
      for x in xs
        return true if f(x)
      return false
    remove = (x, xs) ->
      i = xs.indexOf(x)
      xs.splice(i, 1) if i >= 0
    isFunction = (f) -> typeof f == "function"
    toArray = (x) -> if x instanceof Array then x else [x]

### Exports

We now need to make our objects usable outside.

    Jnoid.EventStream = EventStream
    Jnoid.Event = Event
    Jnoid.Value = Value
    Jnoid.Error = Error
    Jnoid.End = End

    if define?.amd
      define [], -> Jnoid
    else if module?.exports
      module.exports = Jnoid
    else
      @Jnoid = Jnoid

Where to go now
---------------

This is a library that demonstrates lots of interesting things. First of all
it's Functional Reactive Programming paradigm. Second is functional design at
all. We encourage you to try to create your own combinators above to posess
this power.

You can also:

* Read about functional reactive programming on [Haskell
wiki](http://www.haskell.org/haskellwiki/Functional_Reactive_Programming)
* Look at more production-ready [Bacon.js](https://github.com/raimohanska/bacon.js)
* Check the example problem in `examples/` folder. You can run the example via
`npm run-script simple-example`. The very solution is in
[`examples/simple/public/index.html`](https://github.com/it-vecherka/jnoid/blob/master/examples/simple/public/index.html)
