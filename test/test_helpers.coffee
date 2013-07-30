assert = require('chai').assert
{Fire, Error, Stop} = require '../jnoid.coffee.md'

module.exports =
  expectEvents: (expected, stream, done)->
    actual = []
    verify = ->
      [snapshotActual, actual] = [actual, []]
      assert.deepEqual snapshotActual, expected
      done()
    stream.subscribe (event)->
      if event == Stop
        verify()
      else
        actual.push event

  expectValues: (expectedValues, stream, done)->
    @expectEvents(@allValues(expectedValues), stream, done)

  expectErrors: (expectedValues, stream, done)->
    @expectEvents(@allErrors(expectedValues), stream, done)

  value: (x)-> new Fire(x)
  error: (x)-> new Error(x)
  allValues: (xs)-> @value(x) for x in xs
  allErrors: (xs)-> @error(x) for x in xs
