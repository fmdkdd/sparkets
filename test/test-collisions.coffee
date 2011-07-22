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

segments = (points) ->
	type: 'segments'
	points: points

polygon = (points) ->
	type: 'polygon'
	points: points

offset = (x, y) ->
	{x: x, y: y}

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
			points = [
				{x: 1, y: 0},
				{x: 10, y: -1},
				{x: 0, y: 16}]

			assert.deepEqual test(segments(points), offset(-10, 12)),
				type: 'segments'
				points: [
					{x: -9, y: 12},
					{x: 0, y: 11},
					{x: -10, y: 28}]

		'should work on polygons': (test) ->
			points = [
				{x: 1, y: 0},
				{x: 10, y: -1},
				{x: 0, y: 16}]

			assert.deepEqual test(polygon(points), offset(-10, 12)),
				type: 'polygon'
				points: [
					{x: -9, y: 12},
					{x: 0, y: 11},
					{x: -10, y: 28}]

	'circle and circle':
		'should handle floats': () ->
			assert.isTrue(collisions.test(circle(1.01), circle(1, 2)))

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

	'circle and circle - overlapping':
		topic: () ->
			circ = circle(5)

			collisions.test(circ, circ)

		'should collide': (topic) ->
			assert.isTrue(topic)

	'circle and circle - one inside another':
		topic: () ->
			collisions.test(circle(1), circle(2))

		'should collide': (topic) ->
			assert.isTrue(topic)

	'circle with zero radius':
		topic: () ->
			circle(0)

		'should not collide with anything': (circ) ->
			assert.isFalse(collisions.test(circ, circle(10)))

			seg = segments [
				{x: -1, y: 0},
				{x: 1, y: 0}]
			assert.isFalse(collisions.test(circ, seg))

			poly = polygon [
				{x: -1, y: -1},
				{x: 1, y: -1},
				{x: 1, y: 1},
				{x: -1, y: 1}]
			assert.isFalse(collisions.test(circ, poly))

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

	'circle and long segment - nonintersecting':
		topic: () ->
			seg = segments [
				{x: 30, y: 5},
				{x: 30, y: 0},
				{x: 30, y: -5},
				{x: 30, y: -10}]

			collisions.test(circle(10), seg)

		'should not collide': (topic) ->
			assert.isFalse(topic)

	'circle and long segment - intersecting':
		topic: () ->
			seg = segments [
				{x: 5, y: 0},
				{x: 10, y: 0},
				{x: 15, y: 0}]

			collisions.test(circle(10), seg)

		'should collide': (topic) ->
			assert.isTrue(topic)

	'circle and polygon - nonintersecting':
		topic: () ->
			poly = polygon [
				{x: 20, y: 0},
				{x: 40, y: 0},
				{x: 40, y: 20},
				{x: 20, y: 20},]

			collisions.test(circle(10), poly)

		'should not collide': (topic) ->
			assert.isFalse(topic)

	'circle and polygon - intersecting':
		topic: () ->
			poly = polygon [
				{x: -1, y: -1},
				{x: 1, y: -1},
				{x: 1, y: 1},
				{x: -1, y: 1},]

			collisions.test(circle(10), poly)

		'should collide': (topic) ->
			assert.isTrue(topic)

	'empty segment':
		topic: () ->
			segments []

		'should not collide with anything': (seg) ->
			assert.isFalse(collisions.test(seg, circle(1)))

			seg2 = segments [
				{x:-1,y:0},
				{x:1,y:0}]
			assert.isFalse(collisions.test(seg, seg2))

			poly = polygon [
				{x: -1, y: -1},
				{x: 1, y: -1},
				{x: 1, y: 1},
				{x: -1, y: 1}]
			assert.isFalse(collisions.test(seg, poly))

	'zero length segment':
		topic: () ->
			segments [
				{x:0, y:0},
				{x:0, y:0}]

		'should not collide with anything': (seg) ->
			assert.isFalse(collisions.test(seg, circle(1)))

			seg2 = segments [
				{x:-1, y:0},
				{x:1, y:0}]
			assert.isFalse(collisions.test(seg, seg2))

			poly = polygon [
				{x: -1, y: -1},
				{x: 1, y: -1},
				{x: 1, y: 1},
				{x: -1, y: 1}]
			assert.isFalse(collisions.test(seg, poly))

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

	'simple segment and simple segment - intersecting':
		topic: () ->
			seg1 = segments [
				{x: 0, y: 0},
				{x: 10, y: 10}]

			seg2 = segments [
				{x: 0, y: 10},
				{x: 10, y: 0}]

			collisions.test(seg1, seg2)

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

	'simple segment and simple segment - parallel and nonintersecting':
		topic: () ->
			seg1 = segments [
				{x: 0, y: 0},
				{x: 10, y: 0}]

			seg2 = segments [
				{x: 5, y: 5},
				{x: 15, y: 5}]

			collisions.test(seg1, seg2)

		'should not collide': (topic) ->
			assert.isFalse(topic)

	'simple segment and simple segment - parallel and intersecting':
		topic: () ->
			seg1 = segments [
				{x: 0, y: 0},
				{x: 10, y: 0}]

			seg2 = segments [
				{x: 5, y: 0},
				{x: 15, y: 0}]

			collisions.test(seg1, seg2)

		'should collide': (topic) ->
			assert.isTrue(topic)

	'simple segment and long segment - nonintersecting':
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

	'simple segment and long segment - intersecting':
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

	'long segment and long segment - nonintersecting':
		topic: () ->
			seg1 = segments [
				{x: 10, y: 1},
				{x: 15, y: -1},
				{x: 20, y: 9}]

			seg2 = segments [
				{x: -3, y: 0},
				{x: -6, y: 0},
				{x: -8, y: 0},
				{x: 3, y: 0},
				{x: 8, y: 0}]

			collisions.test(seg2, seg1)

		'should not collide': (topic) ->
			assert.isFalse(topic)

	'long segment and long segment - intersecting':
		topic: () ->
			seg1 = segments [
				{x: 0, y: 1},
				{x: 10, y: -1},
				{x: 19, y: 9}]

			seg2 = segments [
				{x: -3, y: 0},
				{x: -6, y: 0},
				{x: -8, y: 0},
				{x: 3, y: 0},
				{x: 8, y: 0}]

			collisions.test(seg2, seg1)

		'should collide': (topic) ->
			assert.isTrue(topic)

	'long segment and long segment - overlapping':
		topic: () ->
			seg = segments [
				{x: 12, y: 12},
				{x: 42, y: -2},
				{x: 0, y: 9}]

			collisions.test(seg, seg)

		'should collide': (topic) ->
			assert.isTrue(topic)

	'simple segment and polygon - nonintersecting':
		topic: () ->
			seg = segments [
				{x: 0, y: 0},
				{x: 10, y: 0}]

			poly = polygon [
				{x: 20, y: 0},
				{x: 40, y: 0},
				{x: 40, y: 20},
				{x: 20, y: 20},]

			collisions.test(seg, poly)

		'should not collide': (topic) ->
			assert.isFalse(topic)

	'simple segment and polygon - intersecting':
		topic: () ->
			seg = segments [
				{x: 15, y: 0},
				{x: 25, y: 0}]

			poly = polygon [
				{x: 20, y: 0},
				{x: 40, y: 0},
				{x: 40, y: 20},
				{x: 20, y: 20},]

			collisions.test(seg, poly)

		'should collide': (topic) ->
			assert.isTrue(topic)

	'long segment and polygon - nonintersecting':
		topic: () ->
			seg = segments [
				{x: 0, y: 0},
				{x: 10, y: 0},
				{x: 15, y: 0},
				{x: 15, y: 5}]

			poly = polygon [
				{x: 20, y: 0},
				{x: 40, y: 0},
				{x: 40, y: 20},
				{x: 20, y: 20},]

			collisions.test(seg, poly)

		'should not collide': (topic) ->
			assert.isFalse(topic)

	'long segment and polygon - intersecting':
		topic: () ->
			seg = segments [
				{x: 15, y: 0},
				{x: 25, y: 0},
				{x: 25, y: 15},
				{x: 25, y: 30}]

			poly = polygon [
				{x: 20, y: 0},
				{x: 40, y: 0},
				{x: 40, y: 20},
				{x: 20, y: 20},]

			collisions.test(seg, poly)

		'should collide': (topic) ->
			assert.isTrue(topic)

	'empty polygon':
		topic: () ->
			poly = polygon []

		'should not collide with anything': (poly) ->
			assert.isFalse(collisions.test(poly, circle(1)))

			seg = segments [
				{x:-1,y:0},
				{x:1,y:0}]
			assert.isFalse(collisions.test(poly, seg))

			poly2 = polygon [
				{x: -1, y: -1},
				{x: 1, y: -1},
				{x: 1, y: 1},
				{x: -1, y: 1}]
			assert.isFalse(collisions.test(poly, poly2))

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

	'polygon and polygon - one inside another':
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

