module?.exports = Jnoid = {}

Jnoid.fromDOM = ($, e)->

# Generators
Jnoid.fromList = (list)->
  new EventStream(sendWrapped(list, toEvent))

Jnoid.unit = (args...)->
  Jnoid.fromList(args)

Jnoid.later = (delay, value)->
  Jnoid.sequentially(delay, [value])

Jnoid.sequentially = (delay, list)->
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

Jnoid.zip = (streams) ->
  if streams.length
    values = (undefined for s in streams)
    new EventStream (sink) =>
      unsubscribed = false
      unsubs = (nop for s in streams)
      unsubAll = (-> f() for f in unsubs ; unsubscribed = true)
      ends = (false for s in streams)
      checkEnd = ->
        if all(ends)
          tap sink(Jnoid.end()), (reply)->
            unsubAll() if reply == Jnoid.noMore
      combiningSink = (markEnd, setValue) ->
        (event) ->
          if (event.isEnd())
            markEnd()
            checkEnd()
            Jnoid.noMore
          else
            setValue(event.value)
            if all(values, (x) -> x != undefined)
              tap sink(toEvent (v for v in values)), (reply)->
                unsubAll() if reply == Jnoid.noMore
            else
              Jnoid.more
      sinkFor = (index) ->
        combiningSink(
          (-> ends[index] = true)
          ((x) -> values[index] = x)
        )
      for stream, index in streams
        unsubs[index] = stream.onValue (sinkFor index) unless unsubscribed
      unsubAll
  else
    Jnoid.unit([])

# Dummy objects for asserting.
# Should not be equal.
Jnoid.more = "<more>"
Jnoid.noMore = "<no more>"

Jnoid.initial = (value) -> new Initial(value)
Jnoid.next = (value) -> new Next(value)
Jnoid.end = -> new End()

class Event
  isEnd: -> false
  isNext: -> false

class Next extends Event
  constructor: (@value) ->
  isNext: -> true
  describe: -> @value
  inspect: -> "Event.Next<#{@value}>"

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
  delay: (delay)->
    @flatMap (x)-> Jnoid.later(delay, x)
  zip: (other)->
    Jnoid.zip([@, other])
  zipWith: (other, f)->
    @zip(other).map(uncurry(f))

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
uncurry = (f) -> (args)-> f(args...)
map = (f, xs) ->
    f(x) for x in xs
all = (xs, f = id) ->
  for x in xs
    return false if not f(x)
  return true
remove = (x, xs) ->
  i = xs.indexOf(x)
  xs.splice(i, 1) if i >= 0
toEvent = (x) -> if x instanceof Event then x else Jnoid.next x
