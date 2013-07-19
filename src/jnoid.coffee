module?.exports = Jnoid = {}

Jnoid.fromDOM = ($, e)->

Jnoid.fromList = (list)->
  new EventStream(sendWrapped(list, toEvent))

sendWrapped = (values, wrapper) ->
  (sink) ->
    sink (wrapper value) for value in values
    sink (Jnoid.end())
    nop

# Dummy objects for asserting.
# Should not be equal.
Jnoid.more = {}
Jnoid.noMore = {}

Jnoid.initial = (value) -> new Initial(value)
Jnoid.next = (value) -> new Next(value)
Jnoid.end = -> new End()

class Event
  isEnd: -> false
  isInitial: -> false
  isNext: -> false

class Next extends Event
  constructor: (@value) ->
  isNext: -> true

class Initial extends Next
  isInitial: -> true

class End extends Event
  constructor: ->
  isEnd: -> true

class EventStream
  constructor: (unfold) ->
    @unfold = new Dispatcher(unfold).unfold
    @onValue = @unfold

class Dispatcher
  constructor: (unfold, handleEvent) ->
    unfold ?= (event) ->
    sinks = []
    @push = (event) =>
      for sink in sinks
        reply = sink event
        remove(sink, sinks) if reply == Jnoid.noMore
      if (sinks.length > 0) then Jnoid.more else Jnoid.noMore
    handleEvent ?= (event) -> @push event
    @handleEvent = (event) =>
      handleEvent.apply(this, [event])
    @unfold = (sink) =>
      sinks.push(sink)
      if sinks.length == 1
        unfold @handleEvent
  toEventStream: -> new EventStream(@subscribe)
  toString: -> "Dispatcher"

nop = ->
empty = (xs) -> xs.length == 0
head = (xs) -> xs[0]
tail = (xs) -> xs[1...xs.length]
toEvent = (x) -> if x instanceof Event then x else Jnoid.next x
