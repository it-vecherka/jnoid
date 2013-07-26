Jnoid
=====

This is a functional reactive programming library in Coffescript to use in
browser or Node.js applications. It owes the idea to Bacon.js, but should
describe the domain in proper terms, have less operations in primitives and be
shorter and simpler.

    Jnoid = {}

The core idea is having an abstraction of `EventStream` which is a discrete
sequence of values and an abstraction of a `Signal` which is a continous
time-varying value, both of which you can subscribe on.

EventStream
-----------

We represent event values as instances of `Maybe` monad. To know about it more,
see section Maybe below. `None` in this case will be thought as the "End of
stream". To do this we'll have type aliases `Event`, `Fire` and `Stop` to
`Maybe` types.

Class `EventStream` will be determined via a `subscribe` function. This
function should receive a subscriber or sink function as an argument and call
it whenever event exists.  This enables push semantics for `EventStream`.

    class EventStream
      constructor: (subscribe)->
        @subscribe = new Dispatcher(subscribe).subscribe

      @newInstance: (args...)-> new EventStream args...
      newInstance: (args...)-> new EventStream args...

The dispatcher wraps subscribe function in a way that only the first subscriber
activates the trail. See appropriate section for more details.

The basic ways to build streams are `never` and `once`.

      @never: ->
        @newInstance (sink) -> sink Stop
      @once: (value)->
        @newInstance (sink) ->
          sink new Fire value
          sink Stop

In our case, `once` is `unit`:

      @unit: @once

### Constructors

`fromBinder` just adds a syntax sugar for us to easily define new constructors.

      @fromBinder: (binder, transform = id) ->
        @newInstance (sink) ->
          unbinder = binder (args...) ->
            events = toArray transform args...
            for event in map toEvent, events
              sink(event)
              unbinder() if event == Stop

`fromPoll` polls a function within given interval.

      @fromPoll: (delay, poll) ->
        @fromBinder (handler) ->
          i = setInterval(handler, delay)
          -> clearInterval(i)
        , poll

`sequentially` and `later` send a fixed list of events or one event
respectively within given interval.

      @sequentially: (delay, list)->
        index = 0
        @fromPoll delay, ->
          value = list[index++]
          if index < list.length
            value
          else if index == list.length
            [value, Stop]
          else
            Stop

      @later: (delay, value)->
          @sequentially(delay, [value])

Dispatcher
----------

`Dispatcher` activates the listeners when a first sink is added and then just
adds them.

    class Dispatcher
      constructor: (subscribe, handleEvent) ->
        subscribe ?= (event) ->
        sinks = []
        @push = (event) =>
          sink(event) for sink in sinks
        handleEvent ?= (event) -> @push event
        @handleEvent = (event) => handleEvent.apply(this, [event])
        @subscribe = (sink) =>
          sinks.push(sink)
          unsubSelf = subscribe @handleEvent if sinks.length == 1
          ->
            remove(sink, sinks)
            unsubSelf?() unless any sinks

Helpers
-------

### Maybe

We represent signal values as instances of `Maybe` monad.

    class Maybe

    class Some extends Maybe
      constructor: (@value) ->
      getOrElse: -> @value
      filter: (f) ->
        if f @value then new Some(@value) else None
      map: (f) ->
        new Some(f @value)
      isEmpty: -> false

    None = new class extends Maybe
      getOrElse: (value) -> value
      filter: -> None
      map: -> None
      isEmpty: -> true

Type aliases for events:

    [Event, Fire, Stop] = [Maybe, Some, None]
    toEvent = (x) -> if x instanceof Event then x else new Fire x

### Our small underscore

We need some simple helper functions.

    empty = (xs) -> xs.length == 0
    head = (xs) -> xs[0]
    tail = (xs) -> xs[1...xs.length]
    map = (f, xs) -> f(x) for x in xs
    toArray = (x) -> if x instanceof Array then x else [x]

Exports
-------

We now need to make our objects usable outside:

    for name, value of {EventStream, Maybe, Some, None,
                                     Event, Fire, Stop}
      Jnoid[name] = value

    if define?.amd
      define [], -> Jnoid
    else if module?.exports
      module.exports = Jnoid
    else
      @Jnoid = Jnoid
