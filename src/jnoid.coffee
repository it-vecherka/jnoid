module?.exports = Jnoid = {}

Jnoid.fromDOM = ($, e)->

Jnoid.fromList = (list)->
  new EventStream(sendWrapped(list, toEvent))

Jnoid.unit = (args...)->
  Jnoid.fromList(args)

sendWrapped = (values, wrapper) ->
  (sink) ->
    sink (wrapper value) for value in values
    sink (Jnoid.end())
    nop

# Dummy objects for asserting.
# Should not be equal.
Jnoid.more = "<more>"
Jnoid.noMore = "<no more>"

Jnoid.initial = (value) -> new Initial(value)
Jnoid.next = (value) -> new Next(value)
Jnoid.end = -> new End()

Jnoid.join = (streamOfStreams)-> streamOfStreams.map(toEvent).flatMap(id)

class Event
  isEnd: -> false
  isInitial: -> false
  isNext: -> false

class Next extends Event
  constructor: (@value) ->
  isNext: -> true
  describe: -> @value
  inspect: -> "Event.Next<#{@value}>"

class Initial extends Next
  isInitial: -> true

class End extends Event
  constructor: ->
  isEnd: -> true
  describe: -> '<end>'
  inspect: -> "Event.End"

class EventStream
  constructor: (unfold) ->
    @unfold = new Dispatcher(unfold).unfold
    @onValue = @unfold
  flatMap: (f, firstOnly) ->
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
          sink Jnoid.end()
      spawner = (event) ->
        if event.isEnd()
          rootEnd = true
          checkEnd()
        else if firstOnly and children.length
          Jnoid.more
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
              tap sink(event), (reply)->
                unbind() if reply == Jnoid.noMore
          unsubChild = child.onValue handler
          children.push unsubChild if not childEnded
      unsubRoot = root.onValue(spawner)
      unbind
  bind: (args...)->
    @flatMap(args...)
  map: (f)->
    @flatMap (x)-> Jnoid.unit(f(x))
  merge: (others...)->
    Jnoid.join Jnoid.fromList([@, others...])

class Dispatcher
  constructor: (unfold, handleEvent) ->
    unfold ?= (event) ->
    sinks = []
    @push = (event) =>
      for sink in sinks
        tap sink(event), (reply)->
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
id = (x)-> x
tap = (x, f) ->
  f(x)
  x
empty = (xs) -> xs.length == 0
head = (xs) -> xs[0]
tail = (xs) -> xs[1...xs.length]
remove = (x, xs) ->
  i = xs.indexOf(x)
  xs.splice(i, 1) if i >= 0
toEvent = (x) -> if x instanceof Event then x else Jnoid.next x
