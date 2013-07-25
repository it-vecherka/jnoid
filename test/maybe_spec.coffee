assert = require('chai').assert
{Maybe, Some, None} = require '../jnoid.coffee.md'

describe 'Maybe', ->
  describe 'Some', ->
    it 'is Maybe', ->
      assert.instanceOf new Some(5), Maybe

    it 'returns value on getOrElse', ->
      assert.equal new Some(5).getOrElse(15), 5

    it 'applies filter', ->
      assert.deepEqual new Some(5).filter((x)-> x > 0), new Some(5)
      assert.deepEqual new Some(5).filter((x)-> x < 0), None

    it 'applies map', ->
      assert.deepEqual new Some(5).map((x)-> x + 10), new Some(15)

    it 'is not empty', ->
      assert.notOk new Some(5).isEmpty()

    it 'wraps to array', ->
      assert.deepEqual new Some(5).toArray(), [5]

  describe 'None', ->
    it 'is Maybe', ->
      assert.instanceOf None, Maybe

    it 'returns else on getOrElse', ->
      assert.equal None.getOrElse(15), 15

    it 'skips filter', ->
      assert.deepEqual None.filter((x)-> x > 0), None

    it 'skips map', ->
      assert.deepEqual None.map((x)-> x + 10), None

    it 'is empty', ->
      assert.ok None.isEmpty()

    it 'wraps to empty array', ->
      assert.deepEqual None.toArray(), []
