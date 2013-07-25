Jnoid
=====

This is a functional reactive programming library in Coffescript to use in
browser or Node.js applications. It owes the idea to Bacon.js, but should
describe the domain in proper terms, have less operations in primitives and be
shorter and simpler.

    Jnoid = {}

The core idea is having an abstraction of `Signal` which is a time-varying
value, which you can subscribe on.

Signal
------

We represent signal values as instances of Maybe monad. To know about it more,
see section Maybe below.

Class `Signal` will be determined via a `subscribe function`.

    class Signal

Boring stuff
------------

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
      toArray: -> [@value]

    class NoneClass extends Maybe
      getOrElse: (value) -> value
      filter: -> None
      map: -> None
      isEmpty: -> true
      toArray: -> []

    None = new NoneClass

### Exports

We now need to make our objects usable outside:

    for name, value of {Signal, Maybe, Some, None}
      Jnoid[name] = value

    if define?.amd
      define [], -> Jnoid
    else if module?.exports
      module.exports = Jnoid
    else
      @Jnoid = Jnoid
