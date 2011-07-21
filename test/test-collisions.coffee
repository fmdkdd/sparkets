vows = require('vows')
assert = require('assert')

# Setup
require('./support/common')
collisions = require '../build/server/collisions'

# Hitboxes constructors.
circle = (radius, x = 0, y = 0) ->
	type: 'circle'
	radius: radius
	x: x
	y: y

segment = (x1, y1, x2, y2) ->
	type: 'segment'
	a: {x: x1, y: y1}
	b: {x: x2, y: y2}

multiseg = (points) ->
	type: 'multisegment'
	points: points

offset = (x, y) ->
	{x: x, y: y}

polygon = (points) ->
	type: 'polygon'
	points: points

exports.suite = vows.describe('Collisions')

exports.suite.addBatch
	'collisions.test':
		topic: () ->
			collisions.test

		'should be symetrical': (test) ->
			assert.equal(test(circle(1), circle(2)), test(circle(2), circle(1)))
			assert.equal(test(circle(1, -1), circle(2)), test(circle(2), circle(1, -1)))

		'should return null for unknown hitboxes': (test) ->
			assert.isNull(test({type: 'zorglub'}, circle(1)))

	'collisions.addOffset':
		topic: () ->
			collisions.addOffset

		'should work on circles': (test) ->
			assert.deepEqual test(circle(1), offset(-10, 12)),
				type: 'circle'
				radius: 1
				x: -10
				y: 12

		'should work on segments': (test) ->
			assert.deepEqual test(segment(-1, 0, 1, 0), offset(-10, 12)),
				type: 'segment'
				a: {x: -11, y: 12}
				b: {x: -9, y: 12}

		'should work on multisegments': (test) ->
			points = [
				{x: 1, y: 0},
				{x: 10, y: -1},
				{x: 0, y: 16}]

			assert.deepEqual test(multiseg(points), offset(-10, 12)),
				type: 'multisegment'
				points: [
					{x: -9, y: 12},
					{x: 0, y: 11},
					{x: -10, y: 28}]

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
			circle(0)

		'should not collide with anything': (circ) ->
			assert.isFalse(collisions.test(circ, circle(1)))
			assert.isFalse(collisions.test(circ, segment(0,1,-0,1)))

	'circle and segment - nonintersecting':
		topic: () ->
			collisions.test(circle(10), segment(30, 0, 35, 0))

		'should not collide': (topic) ->
			assert.isFalse(topic)

	'circle and segment - intersecting':
		topic: () ->
			collisions.test(circle(10), segment(5, 0, 15, 0))

		'should collide': (topic) ->
			assert.isTrue(topic)

	'circle and multisegment - nonintersecting':
		topic: () ->
			collisions.test circle(10), multiseg [
				{x: 30, y: 5},
				{x: 30, y: 0},
				{x: 30, y: -5},
				{x: 30, y: -10}]

		'should not collide': (topic) ->
			assert.isFalse(topic)

	'circle and multisegment - intersecting':
		topic: () ->
			collisions.test circle(10), multiseg [
				{x: 5, y: 0},
				{x: 10, y: 0},
				{x: 15, y: 0}]

		'should collide': (topic) ->
			assert.isTrue(topic)

	'segment and segment - overlapping':
		topic: () ->
			collisions.test(segment(0,0,1,0), segment(0,0,1,0))

		'should collide': (topic) ->
			assert.isTrue(topic)

	'segment and segment - nonintersecting':
		topic: () ->
			collisions.test(segment(0,0,10,0), segment(20,5,20,-5))

		'should not collide': (topic) ->
			assert.isFalse(topic)

	'zero length segment':
		topic: () ->
			segment(0,0,0,0)

		'should not collide with anything': (seg) ->
			assert.isFalse(collisions.test(seg, segment(-1,0,1,0)))
			assert.isFalse(collisions.test(seg, circle(1)))

	'segment and segment - intersecting':
		topic: () ->
			collisions.test(segment(0,0,10,0), segment(5,5,5,-5))

		'should collide': (topic) ->
			assert.isTrue(topic)

	'segment and multisegment - nonintersecting':
		topic: () ->
			collisions.test segment(0,0,10,0), multiseg [
				{x: 20, y:20},
				{x: 20, y:15},
				{x: 20, y:10}]

		'should not collide': (topic) ->
			assert.isFalse(topic)

	'segment and multisegment - intersecting':
		topic: () ->
			collisions.test segment(0,0,10,0), multiseg [
				{x: 5, y: 5},
				{x: 5, y: -5},
				{x: 5, y: -10}]

		'should collide': (topic) ->
			assert.isTrue(topic)

	'multisegment and multisegment - overlapping':
		topic: () ->
			mseg = multiseg([{x: 12, y: 12}, {x: 42, y: -2}, {x: 0, y: 9}])

			collisions.test(mseg, mseg)

		'should collide': (topic) ->
			assert.isTrue(topic)

	'zero length multisegment':
		topic: () ->
			multiseg([])

		'should not collide with anything': (mseg) ->
			assert.isFalse(collisions.test(mseg, circle(1)))
			assert.isFalse(collisions.test(mseg, segment(-1,0,1,0)))

	'multisegment and multisegment - nonintersecting':
		topic: () ->
			mseg1 = multiseg [
				{x: 0, y: 0},
				{x: 10, y: -10},
				{x: 20, y: 0}]

			mseg2 = multiseg [
				{x: 1, y: 1}
				{x: 1, y: 10}]

			collisions.test(mseg1, mseg2)

		'should not collide': (topic) ->
			assert.isFalse(topic)

	'multisegment and multisegment - intersecting':
		topic: () ->
			mseg1 = multiseg [
				{x: 0, y: 0},
				{x: 10, y: -10},
				{x: 20, y: 0}]

			mseg2 = multiseg [
				{x: 1, y: 1}
				{x: 10, y: -20}]

			collisions.test(mseg1, mseg2)

		'should collide': (topic) ->
			assert.isTrue(topic)

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
