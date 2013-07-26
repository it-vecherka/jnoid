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
stream".

Class `EventStream` will be determined via a `subscribe` function. This
function should receive a subscriber or sink function as an argument and call
it whenever event exists.  This enables push semantics for `EventStream`.

    class EventStream

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
