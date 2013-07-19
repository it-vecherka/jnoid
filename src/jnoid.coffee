Jnoid = {}

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
  Jnoid.fromPoll delay,->
    value = list[index++]
    if index < list.length
      value
    else if index == list.length
      [value, Jnoid.end()]
    else
      Jnoid.end()

Jnoid.fromPoll = (delay, poll) ->
  Jnoid.fromBinder (handler) ->
    id = setInterval(handler, delay)
    -> clearInterval(id)
  , poll


Jnoid.fromPromise = (promise) ->
  Jnoid.fromBinder (handler) ->
    promise.then(handler, (e) -> handler(Jnoid.error(e)))
    -> promise.abort?()
  , (value) -> [value, Jnoid.end()]

Jnoid.fromBinder = (binder, transform = id) ->
  new EventStream (sink) ->
    unbinder = binder (args...) ->
      events = toArray transform args...
      for e in events
        event = toEvent e
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

Jnoid.zip = (streams, endChecker = all) ->
  if streams.length
    values = (undefined for s in streams)
    new EventStream (sink) =>
      unsubscribed = false
      unsubs = (nop for s in streams)
      unsubAll = (-> f() for f in unsubs ; unsubscribed = true)
      ends = (false for s in streams)
      checkEnd = ->
        if endChecker(ends)
          tap sink(Jnoid.end()), (reply)->
            unsubAll() if reply == Jnoid.noMore
      combiningSink = (markEnd, setValue) ->
        (event) ->
          if (event.isEnd())
            markEnd()
            checkEnd()
            Jnoid.noMore
          else if event.isError()
            tap sink(event), (reply) ->
              unsubAll() if reply == Bacon.noMore
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

Jnoid.zipAndStop = (streams)->
  Jnoid.zip(streams, any)

# Dummy objects for asserting.
# Should not be equal.
Jnoid.more = "<more>"
Jnoid.noMore = "<no more>"

Jnoid.next = (value) -> new Next(value)
Jnoid.error = (error) -> new Error(error)
Jnoid.end = -> new End()

class Event
  isEnd: -> false
  isNext: -> false
  isError: -> false
  filter: -> true

class Next extends Event
  constructor: (@value) ->
  isNext: -> true
  describe: -> @value
  inspect: -> "Event.Next<#{@value}>"
  filter: (f)-> f(@value)

class Error extends Event
  constructor: (@error) ->
  isError: -> true
  describe: -> "<error> #{@error}"
  inspect: -> "Event.Error<#{@error}>"

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
        else if event.isError()
          sink event
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
  zipAndStop: (other)->
    Jnoid.zipAndStop([@, other])
  zipWith: (other, f)->
    @zip(other).map(uncurry(f))
  zipWithAndStop: (other, f)->
    @zipAndStop(other).map(uncurry(f))
  and: (other)->
    @zipWith(other, (a, b)-> a && b)
  or: (other)->
    @zipWith(other, (a, b)-> a || b)
  not: -> @map (x)-> !x
  log: (args...) ->
    @onValue (event) -> console?.log?(args..., event.describe())
    this
  withHandler: (handler) ->
    dispatcher = new Dispatcher(@unfold, handler)
    new EventStream(dispatcher.unfold)
  filter: (f) ->
    @withHandler (event) ->
      if event.filter(f)
        @push event
      else
        Jnoid.more
  onlyEnd: -> @filter -> false
  prepend: (x)-> Jnoid.unit(x).merge(@)
  takeWhile: (f) ->
    @withHandler (event) ->
      if event.filter(f)
        @push event
      else
        @push Jnoid.end()
        Jnoid.noMore
  takeUntil: (stopper)->
    @zipWithAndStop(stopper.onlyEnd().prepend(1), left)

class Dispatcher
  constructor: (unfold, handleEvent) ->
    unfold ?= (event) ->
    sinks = []
    @push = (event) =>
      for sink in sinks
        tap sink(event), (reply) =>
          remove(sink, sinks) if reply == Jnoid.noMore
      if (sinks.length > 0) then Jnoid.more else Jnoid.noMore
    handleEvent ?= (event) -> @push event
    @handleEvent = (event) => handleEvent.apply(this, [event])
    @unfold = (sink) =>
      sinks.push(sink)
      unsubSelf = unfold @handleEvent
      ->
        remove(sink, sinks)
        unsubSelf() unless any sinks
  toString: -> "Dispatcher"

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
toArray = (x) -> if x instanceof Array then x else [x]
toEvent = (x) -> if x instanceof Event then x else Jnoid.next x


# we support AMD, nodejs, browsers
if define?.amd
  define [], -> Jnoid
else if module?.exports
  module.exports = Jnoid
else
  @Jnoid = Jnoid
