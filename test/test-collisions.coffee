vows = require('vows')
assert = require('assert')

# Setup
require('./support/common')
collisions = require '../build/server/collisions'

# Mock-up game object class.
class MockGameObject
	constructor: (x = 0, y = 0) ->
		@pos = {x: x, y: y}

exports.suite = vows.describe('Collisions')

exports.suite.addBatch
	'circle and circle - nonintersecting':
		topic: () ->
			obj1 = new MockGameObject()
			obj1.hitBox = 
				type: 'circle'
				radius: 10

			obj2 = new MockGameObject(30, 0)
			obj2.hitBox = 
				type: 'circle'
				radius: 10

			collisions.test(obj1, obj2)

		'should return false': (topic) ->
			assert.strictEqual(topic, false)

	'circle and circle - intersecting':
		topic: () ->
			obj1 = new MockGameObject()
			obj1.hitBox = 
				type: 'circle'
				radius: 10

			obj2 = new MockGameObject(5, 0)
			obj2.hitBox = 
				type: 'circle'
				radius: 10

			collisions.test(obj1, obj2)

		'should return true': (topic) ->
			assert.strictEqual(topic, true)

	'circle and segment - nonintersecting':
		topic: () ->
			obj1 = new MockGameObject()
			obj1.hitBox = 
				type: 'circle'
				radius: 10

			obj2 = new MockGameObject()
			obj2.hitBox = 
				type: 'segment'
				a:
					x: 30
					y: 0
				b:
					x: 35
					y: 0

			collisions.test(obj1, obj2)

		'should return false': (topic) ->
			assert.strictEqual(topic, false)

	'circle and segment - intersecting':
		topic: () ->
			obj1 = new MockGameObject()
			obj1.hitBox = 
				type: 'circle'
				radius: 10

			obj2 = new MockGameObject()
			obj2.hitBox = 
				type: 'segment'
				a:
					x: 5
					y: 0
				b:
					x: 15
					y: 0

			collisions.test(obj1, obj2)

		'should return true': (topic) ->
			assert.strictEqual(topic, true)
