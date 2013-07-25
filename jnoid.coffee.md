Jnoid
=====

Here be dragons.

    Jnoid = {}


Boring stuff
------------

### Exports

We now need to make our objects usable outside:

    if define?.amd
      define [], -> Jnoid
    else if module?.exports
      module.exports = Jnoid
    else
      @Jnoid = Jnoid
