vows = require('vows')
assert = require('assert')

# Setup
require('./support/common')
collisions = require '../build/server/collisions'

# Mock-up game object class.
class MockGameObject
	constructor: (x = 0, y = 0) ->
		@pos = {x: x, y: y}

circle = (radius, x, y) ->
	obj = new MockGameObject(x, y)
	obj.hitBox =
		type: 'circle'
		radius: radius
	return obj

segments = (points) ->
	obj = new MockGameObject()
	obj.hitBox =
		type: 'segments'
		points: points
	return obj

polygon = (points) ->
	obj = new MockGameObject()
	obj.hitBox =
		type: 'polygon'
		points: points
	return obj

exports.suite = vows.describe('Collisions')

exports.suite.addBatch
	'collision.test':
		topic: () ->
			collisions.test

		'should be symetrical': (test) ->
			assert.equal(test(circle(1), circle(2)), test(circle(2), circle(1)))
			assert.equal(test(circle(1, -1), circle(2)), test(circle(2), circle(1, -1)))

		'should return null for unknown hitboxes': (test) ->
			assert.isNull(test({hitBox: type: 'zorglub'}, circle(1)))

	'circle and circle - nonintersecting':
		topic: () ->
			collisions.test(circle(10), circle(10, 30, 0))

		'should not collide': (topic) ->
			assert.isFalse(topic)

	'circle and circle - intersecting':
		topic: () ->
			collisions.test(circle(10), circle(10, 5, 0))

		'should collide': (topic) ->
			assert.isTrue(topic)

	'circle and circle':
		'should handle floats': () ->
			assert.isTrue(collisions.test(circle(1.01), circle(1, 2)))

	'circle inside circle':
		topic: () ->
			collisions.test(circle(1), circle(2))

		'should collide': (topic) ->
			assert.isTrue(topic)

	'zero radius circle':
		topic: () ->
			seg = segments [
				{x: 0, y: 1},
				{x: 0, y: 2}]

		'should not collide with anything': (seg) ->
			assert.isFalse(collisions.test(circle(0), circle(1)))
			assert.isFalse(collisions.test(circle(0), seg))

	'circle and simple segment - nonintersecting':
		topic: () ->
			seg = segments [
				{x: 30, y: 0},
				{x: 35, y: 0}]

			collisions.test(circle(10), seg)

		'should not collide': (topic) ->
			assert.isFalse(topic)

	'circle and simple segment - intersecting':
		topic: () ->
			seg = segments [
				{x: 5, y: 0},
				{x: 15, y: 0}]

			collisions.test(circle(10), seg)

		'should collide': (topic) ->
			assert.isTrue(topic)

	'circle and multiple segment - nonintersecting':
		topic: () ->
			seg = segments [
				{x: 30, y: 5},
				{x: 30, y: 0},
				{x: 30, y: -5},
				{x: 30, y: -10}]

			collisions.test(circle(10), seg)

		'should not collide': (topic) ->
			assert.isFalse(topic)

	'circle and multiple segment - intersecting':
		topic: () ->
			seg = segments [
				{x: 5, y: 0},
				{x: 10, y: 0},
				{x: 15, y: 0}]

			collisions.test(circle(10), seg)

		'should collide': (topic) ->
			assert.isTrue(topic)

	'simple segment and simple segment - overlapping':
		topic: () ->
			seg = segments [
				{x:0, y:0},
				{x:1, y:0}]

			collisions.test(seg, seg)

		'should collide': (topic) ->
			assert.isTrue(topic)

	'simple segment and simple segment - nonintersecting':
		topic: () ->
			seg1 = segments [
				{x:0, y:0},
				{x:10, y:0}]

			seg2 = segments [
				{x:20, y:5},
				{x:20, y:-5}]

			collisions.test(seg1, seg2)

		'should not collide': (topic) ->
			assert.isFalse(topic)

	'zero length segment':
		topic: () ->
			segments [{x:0, y:0}, {x:0, y:0}]

		'should not collide with anything': (seg) ->
			assert.isFalse(collisions.test(seg, segments([{x:-1,y:0},{x:1,y:0}])))
			assert.isFalse(collisions.test(seg, circle(1)))

	'simple segment and multiple segment - nonintersecting':
		topic: () ->
			seg1 = segments [
				{x: 0, y: 0},
				{x: 10, y: 0}]

			seg2 = segments [
				{x: 20, y:20},
				{x: 20, y:15},
				{x: 20, y:10}]

			collisions.test(seg1, seg2)

		'should not collide': (topic) ->
			assert.isFalse(topic)

	'simple segment and multiple segment - intersecting':
		topic: () ->
			seg1 = segments [
				{x: 0, y: 0},
				{x: 10, y: 0}]

			seg2 = segments [
				{x: 5, y: 5},
				{x: 5, y: -5},
				{x: 5, y: -10}]

			collisions.test(seg1, seg2)

		'should collide': (topic) ->
			assert.isTrue(topic)

	'multiple segment and multiple segment - overlapping':
		topic: () ->
			seg = segments [
				{x: 12, y: 12},
				{x: 42, y: -2},
				{x: 0, y: 9}]

			collisions.test(seg, seg)

		'should collide': (topic) ->
			assert.isTrue(topic)

	'segment without any point':
		topic: () ->
			segments []

		'should not collide with anything': (seg) ->
			assert.isFalse(collisions.test(seg, circle(1)))
			assert.isFalse(collisions.test(seg, segments([{x:-1,y:0},{x:1,y:0}])))

	'polygon and polygon - nonintersecting':
		topic: () ->
			poly1 = polygon [
				{x: 0, y: 0},
				{x: 10, y: 0},
				{x: 5, y: 5}]

			poly2 = polygon [
				{x: 20, y: 0},
				{x: 30, y: 0},
				{x: 30, y: 10},
				{x: 20, y: 10}]

			collisions.test(poly1, poly2)

		'should not collide': (topic) ->
			assert.isFalse(topic)

	'polygon and polygon - intersecting':
		topic: () ->
			poly1 = polygon [
				{x: 0, y: 0},
				{x: 10, y: 0},
				{x: 5, y: 5}]

			poly2 = polygon [
				{x: 5, y: 0},
				{x: 15, y: 0},
				{x: 15, y: 10},
				{x: 5, y: 10}]

			collisions.test(poly1, poly2)

		'should collide': (topic) ->
			assert.isTrue(topic)

	'polygon and polygon - overlapping':
		topic: () ->
			poly = polygon [
				{x: 0, y: 0},
				{x: 10, y: 0},
				{x: 5, y: 5}]

			collisions.test(poly, poly)

		'should collide': (topic) ->
			assert.isTrue(topic)

	'polygon and polygon - sharing a unique point':
		topic: () ->
			poly1 = polygon [
				{x: 0, y: 0},
				{x: 10, y: 0},
				{x: 5, y: 5}]

			poly2 = polygon [
				{x: 10, y: 0},
				{x: 20, y: 0},
				{x: 15, y: 5}]

			collisions.test(poly1, poly2)

		'should collide': (topic) ->
			assert.isTrue(topic)

	'polygon inside polygon':
		topic: () ->
			poly1 = polygon [
				{x: 0, y: 0},
				{x: 10, y: 0},
				{x: 10, y: 10},
				{x: 0, y: 10}]

			poly2 = polygon [
				{x: 3, y: 3},
				{x: 6, y: 3},
				{x: 6, y: 6},
				{x: 3, y: 6}]

			collisions.test(poly1, poly2)

		'should collide': (topic) ->
			assert.isTrue(topic)

	'polygon reduced to a unique point':
		topic: () ->
			poly1 = polygon [
				{x: 0, y: 0},
				{x: 10, y: 0},
				{x: 10, y: 10},
				{x: 0, y: 10}]

			poly2 = polygon [
				{x: 5, y: 5},
				{x: 5, y: 5},
				{x: 5, y: 5}]

			collisions.test(poly1, poly2)

		'should not collide with anything': (topic) ->
			assert.isFalse(topic)

