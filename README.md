Jnoid
=====

This is a functional reactive programming library in Coffescript to use in
browser or Node.js applications. It owes the idea to Bacon.js, but should
describe the domain in proper terms, have less operations in primitives and be
shorter and simpler.
```coffeescript
Jnoid = {}
```
The core idea is having an abstraction of `Stream` which is a discrete
sequence of values and an abstraction of a `Box` which is a continous
time-varying value, both of which you can subscribe on.

Observable
----------

The point is that we can abstract from both of them and define a common
behavior, calling it `Observable`.

We represent event values as instances of `Event` monad. It is semantically
equivalent to famous `Maybe` monad, and in fact is just a type alias. To know
about it more, see section Maybe below. Aliases are `Event` for `Maybe`, `Fire`
for `Some` and `Stop` for `End`.

Class `Observable` will be determined via a `subscribe` function. This
function should receive a subscriber or sink function as an argument and
call it whenever event is fired. This enables push semantics for `Stream`
and `Box`.

There are two ways to unsubscribe. First is to call function that subscribe
returns. Second is return `Reply.stop` from event listener.
```coffeescript
Reply =
  stop: "<stop>"
  more: "<more>"

class Observable
  constructor: (subscribe)->
    @subscribe = @dispatched subscribe

  dispatched: fail
  newInstance: fail
```
We can now define basic transforms. Start with `map` and `filter`. We can
see common pattern there, it's abstracted in `withHandler`.
```coffeescript
  withHandler: (handler)->
    @newInstance @dispatched(@subscribe, handler)

  map: (f)->
    @withHandler (event)->
      @push event.map(f)

  filter: (f)->
    @withHandler (event)->
      if event.test(f) then @push event else Reply.more
```
EventStream
-----------

Class `EventStream` represents a disrete sequence of values, coupled with time.
So it uses the appropriate dispatcher to do it.

`Dispatcher` activates the listeners when a first sink is added and then just
adds them. On each event it just pushes it to all sinks.
```coffeescript
class Stream extends Observable
  class Dispatcher
    constructor: (subscribe, handler) ->
      subscribe ?= (event) ->
      sinks = []
      @push = (event) =>
        for sink in sinks
          tap sink(event), (reply)->
            remove sink, sinks if reply == Reply.stop
      handler ?= (event) -> @push event
      @handler = (event) => handler.apply(this, [event])
      @subscribe = (sink) =>
        sinks.push(sink)
        unsubSelf = subscribe @handler if sinks.length == 1
        ->
          remove sink, sinks
          unsubSelf?() unless any sinks

  dispatched: (subscribe, handler)->
    new Dispatcher(subscribe, handler).subscribe
  newInstance: (args...)-> new Stream args...
```
The basic ways to build streams are `never` and `once`.
```coffeescript
  @never: ->
    new Stream (sink) -> sink Stop
  @once: (value)->
    new Stream (sink) ->
      sink new Fire value
      sink Stop
```
In our case, `once` is `unit`:
```coffeescript
  @unit: @once
```
### flatMap

Once we have unit, we should definitely have `flatMap`. `flatMap` takes function that accepts a value from events and spawns a stream. `flatMap` returns a stream that pushes events from that stream. Once a new event appears on that stream, 

### Constructors

`fromBinder` just adds a syntax sugar for us to easily define new constructors.
```coffeescript
  @fromBinder: (binder, transform = id) ->
    new Stream (sink) ->
      unbinder = binder (args...) ->
        events = toArray transform args...
        for event in map toEvent, events
          tap sink(event), (reply)->
            unbinder() if event == Stop or reply == Reply.stop
```
`fromPoll` polls a function within given interval.
```coffeescript
  @fromPoll: (delay, poll) ->
    @fromBinder (handler) ->
      i = setInterval(handler, delay)
      -> clearInterval(i)
    , poll
```
`sequentially` and `later` send a fixed list of events or one event
respectively within given interval.
```coffeescript
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
```
Helpers
-------

### Maybe

We represent signal values as instances of `Maybe` monad.
```coffeescript
class Maybe

class Some extends Maybe
  constructor: (@value) ->
  getOrElse: -> @value
  filter: (f) ->
    if f @value then new Some(@value) else None
  test: (f) ->
    f @value
  map: (f) ->
    new Some(f @value)
  isEmpty: -> false

None = new class extends Maybe
  getOrElse: (value) -> value
  filter: -> None
  test: -> true
  map: -> None
  isEmpty: -> true
```
Type aliases for events:
```coffeescript
[Event, Fire, Stop] = [Maybe, Some, None]
toEvent = (x) -> if x instanceof Event then x else new Fire x
```
### Our small underscore

We need some simple helper functions.
```coffeescript
empty = (xs) -> xs.length == 0
fail = -> throw "method not implemented"
head = (xs) -> xs[0]
tail = (xs) -> xs[1...xs.length]
map = (f, xs) -> f(x) for x in xs
tap = (x, f) ->
  f(x)
  x
remove = (x, xs) ->
  i = xs.indexOf(x)
  xs.splice(i, 1) if i >= 0
toArray = (x) -> if x instanceof Array then x else [x]
```
Exports
-------

We now need to make our objects usable outside:
```coffeescript
for name, value of {Stream, Maybe, Some, None,
                            Event, Fire, Stop}
  Jnoid[name] = value

if define?.amd
  define [], -> Jnoid
else if module?.exports
  module.exports = Jnoid
else
  @Jnoid = Jnoid
```
Conclusion
----------

Have fun!
