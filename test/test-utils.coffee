vows = require('vows')
assert = require('assert')

# Setup
utils = require('../build/utils')

exports.suite = vows.describe('Utils')

exports.suite.addBatch
	'Array.random':
		topic: () ->
			Array.random

		'should return element from array': (random) ->
			array = ['a', 'b', 1, 2, {bob: 'bob'}]
			assert.include(array, random(array))

		'should work with arrays of one element': (random) ->
			assert.strictEqual(random([42]), 42)

		'should return undefined for empty arrays': (random) ->
			assert.isUndefined(random([]))

exports.suite.addBatch
	'randomObjectElem':
		topic: () ->
			utils.randomObjectElem

		'should return object property': (random) ->
			obj =
				a: 42
				b: 42
				c: 42

			assert.strictEqual(random(obj), 42)

		'should work with objects with one key': (random) ->
			assert.strictEqual(random({a:'a'}), 'a')

		'should return undefined for empty objects': (random) ->
			assert.isUndefined(random({}))

exports.suite.addBatch
	'isEmptyObject':
		topic: () ->
			utils.isEmptyObject

		'should return true on empty objects': (test) ->
			assert.isTrue(test({}))

		'should return false on non-empty objects': (test) ->
			assert.isFalse(test({a: 1}))

exports.suite.addBatch
	'deepCopy':
		topic: () ->
			obj1 =
				a: 'a'
				b: {c: 3}
				d: [1,2,3]
			obj2 = utils.deepCopy(obj1)

			@callback(null, obj1, obj2)
			return

		'should return different objects': (err, orig, copy) ->
			assert.notEqual(orig, copy)

		'shoud copy objects recursively': (err, orig, copy) ->
			assert.notEqual(orig.b, copy.b)
			assert.notEqual(orig.d, copy.d)

		'should copy nested objects properly': (err, orig, copy) ->
			assert.deepEqual(orig, copy)

exports.suite.addBatch
	'safeDeepMerge':
		topic: () ->
			obj1 =
				a: 'a'
				b: {c: 3}
				d: [1,2,3]
			obj2 =
				a: 'b'
				d: [3,2,1]

			utils.safeDeepMerge(obj1, obj2)

			@callback(null, obj1, obj2)
			return

		'should merge existing properties': (err, orig, merged) ->
			assert.deepEqual(merged.a, orig.a)
			assert.deepEqual(merged.d, orig.d)

		'should not create additional properties': (err, orig, merged) ->
			assert.isUndefined(merged.b)

exports.suite.addBatch
	'deepMerge':
		topic: () ->
			obj1 =
				a: 'a'
				b: {c: 3}
				d: [1,2,3]
			obj2 =
				a: 'b'
				d: [3,2,1]
				e: 'e'

			utils.deepMerge(obj1, obj2)

			@callback(null, obj1, obj2)
			return

		'should merge all properties': (err, orig, merged) ->
			assert.deepEqual(merged.a, orig.a)
			assert.deepEqual(merged.b, orig.b)
			assert.deepEqual(merged.d, orig.d)

		'should leave existing properties alone': (err, orig, merged) ->
			assert.strictEqual(merged.e, 'e')