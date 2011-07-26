vows = require('vows')
assert = require('assert')

# Setup
require('./support/common')
Ship = require('../build/server/ship').Ship

# Mock-up game class.
class MockGame
	constructor: () ->
		@bullets = {}

		@events =
			push: () ->

		@prefs =
			mapSize: 2000

			ship:
				states:
					'spawned':
						next: 'alive'
						countdown: 1500
					'alive':
						next: 'exploding'
						countdown: null
					'exploding':
						next: 'dead'
						countdown: 1000
					'dead':
						next: 'alive'
						countdown: null

				boundingRadius: 9
				dirInc: 0.12
				speed: 0.3
				frictionDecay: 0.97
				minFirepower: 1.3
				firepowerInc: 0.1
				maxFirepower: 3
				cannonCooldown: 20
				maxExploFrame: 50
				enableGravity: false

			bullet:
				boundingRadius: 2

			shield:
				shipPush: -200

			debug:
				sendHitBoxes: no

	newGameObject: (fun) ->
		fun(0)

	collidesWithPlanet: (ship) ->
		no

exports.suite = vows.describe('Server ship')

events = require('events')

exports.suite.addBatch
	'ship spawning':
		topic: () ->
			game = new MockGame()
			ship = new Ship(0, game, 0)

			ship.on 'spawned', waiter(@callback)
			ship.spawn()
			return

		'should send `spawned` event': (err, ship) ->
			assert.isNull(err)
			assert.isObject(ship)
			assert.strictEqual(ship.type, 'ship')

	'ship moving':
		topic: () ->
			game = new MockGame()
			ship = new Ship(0, game, 0)

			ship.on 'moved', waiter(@callback)
			ship.move()
			return

		'should send `moved` event': (err, ship) ->
			assert.isNull(err)
			assert.isObject(ship)
			assert.strictEqual(ship.type, 'ship')

	'ship firing':
		topic: () ->
			game = new MockGame()
			ship = new Ship(0, game, 0)

			ship.on 'fired', waiter(@callback)
			ship.spawn()
			ship.nextState()
			ship.fire()
			return

		'should send `fired` event': (err, ship, bullet) ->
			assert.isNull(err)

			assert.isObject(ship)
			assert.strictEqual(ship.type, 'ship')

			assert.isObject(bullet)
			assert.strictEqual(bullet.type, 'bullet')

	'ship exploding':
		topic: () ->
			game = new MockGame()
			ship = new Ship(0, game, 0)

			ship.on 'exploded', waiter(@callback)
			ship.spawn()
			ship.explode()
			return

		'should send `exploded` event': (err, ship) ->
			assert.isNull(err)
			assert.isObject(ship)
			assert.strictEqual(ship.type, 'ship')
