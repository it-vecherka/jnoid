module?.exports = Jnoid = {}

Jnoid.fromDOM = ($, e)->

# Generators
Jnoid.fromList = (list)->
  new EventStream(sendWrapped(list, toEvent))

Jnoid.unit = (args...)->
  Jnoid.fromList(args)

Jnoid.later = (value, delay)->
  Jnoid.sequentially([value], delay)

Jnoid.sequentially = (list, delay)->
  index = 0
  Jnoid.fromPoll delay, ->
    value = list[index++]
    if index <= list.length
      value
    else
      Jnoid.end()

Jnoid.fromPoll = (delay, poll) ->
  Jnoid.fromBinder (handler) ->
    id = setInterval(handler, delay)
    -> clearInterval(id)
  , poll

Jnoid.fromBinder = (binder, transform = id) ->
  new EventStream (sink) ->
    unbinder = binder (args...) ->
      event = toEvent transform args...
      tap sink(event), (reply)->
        unbinder() if reply == Jnoid.noMore or event.isEnd()

sendWrapped = (values, wrapper) ->
  (sink) ->
    sink (wrapper value) for value in values
    sink (Jnoid.end())
    nop

# Processors
Jnoid.join = (streamOfStreams)-> streamOfStreams.flatMap(id)
Jnoid.flatten = Jnoid.join

# Dummy objects for asserting.
# Should not be equal.
Jnoid.more = "<more>"
Jnoid.noMore = "<no more>"

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
  constructor: (unfold) ->
    unfold ?= (event) ->
    sinks = []
    @push = (event) =>
      for sink in sinks
        tap sink(event), (reply)->
          remove(sink, sinks) if reply == Jnoid.noMore
      if (sinks.length > 0) then Jnoid.more else Jnoid.noMore
    @unfold = (sink) =>
      sinks.push(sink)
      if sinks.length == 1
        unfold @push
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
