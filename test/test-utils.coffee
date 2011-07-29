vows = require('vows')
assert = require('assert')

# Setup
utils = require('../build/utils')

exports.suite = vows.describe('Utils')
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
