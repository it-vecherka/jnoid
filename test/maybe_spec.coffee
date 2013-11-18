assert = require('chai').assert
{Maybe, Just, Wrong, Nothing} = require '../jnoid'

describe 'Maybe', ->
  describe 'Just', ->
    it 'is Maybe', ->
      assert.instanceOf new Just(5), Maybe

    it 'returns value on getOrElse', ->
      assert.equal new Just(5).getOrElse(15), 5

    it 'applies filter', ->
      assert.deepEqual new Just(5).filter((x)-> x > 0), new Just(5)
      assert.deepEqual new Just(5).filter((x)-> x < 0), Nothing

    it 'tests', ->
      assert.ok new Just(5).test((x)-> x > 0)
      assert.notOk new Just(5).test((x)-> x < 0)

    it 'applies map', ->
      assert.deepEqual new Just(5).map((x)-> x + 10), new Just(15)

    it 'is not empty', ->
      assert.notOk new Just(5).isEmpty()

  describe 'Wrong', ->
    it 'is Maybe', ->
      assert.instanceOf new Wrong(5), Maybe

    it 'returns else on getOrElse', ->
      assert.equal new Wrong(5).getOrElse(15), 15

    it 'skips filter', ->
      assert.deepEqual new Wrong(5).filter((x)-> x > 0), new Wrong(5)

    it 'passes test', ->
      assert.ok new Wrong(5).test((x)-> x < 0)

    it 'skips map', ->
      assert.deepEqual new Wrong(5).map((x)-> x + 10), new Wrong(5)

    it 'is empty', ->
      assert.ok new Wrong(5).isEmpty()

    it 'gives error on demand', ->
      assert.equal new Wrong(5).error, 5

  describe 'Nothing', ->
    it 'is Maybe', ->
      assert.instanceOf Nothing, Maybe

    it 'returns else on getOrElse', ->
      assert.equal Nothing.getOrElse(15), 15

    it 'skips filter', ->
      assert.deepEqual Nothing.filter((x)-> x < 0), Nothing

    it 'passes test', ->
      assert.ok Nothing.test((x)-> x > 0)

    it 'skips map', ->
      assert.deepEqual Nothing.map((x)-> x + 10), Nothing

    it 'is empty', ->
      assert.ok Nothing.isEmpty()
