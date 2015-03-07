vows = require('vows')
assert = require('assert')

# Setup
require('./support/common')
Ship = require('../build/server/ship').Ship

# Mock-up game class.
class MockGame
  constructor: () ->
    @bullets = {}
    @shields = {}

    @events =
      push: () ->

    @prefs =
      mapSize: 2000

      ship:
        states:
          'ready':
            next: 'alive'
            countdown: null
          'alive':
            next: 'dead'
            countdown: null
          'dead':
            next: 'ready'
            countdown: null

        boundingRadius: 9
        dirInc: 0.12
        speed: 0.3
        frictionDecay: 0.97
        minFirepower: 1.3
        firepowerInc: 0.1
        maxFirepower: 3
        cannonCooldown: 20
        enableGravity: false

      bullet:
        boundingRadius: 2

      shield:
        shipPush: -200

        states:
          'active':
            countdown: 5000
            next: 'dead'

          'dead':
            countdown: null
            next: null

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

      ship.spawn()
      return ship

    'should move to `alive` state': (err, ship) ->
      assert.isNull(err)
      assert.isObject(ship)
      assert.strictEqual(ship.state, 'alive')

    'should have a shield': (err, ship) ->
      assert.isObject(ship.shield)
      assert.strictEqual(ship.shield.type, 'shield')

  'ship exploding':
    topic: () ->
      game = new MockGame()
      ship = new Ship(0, game, 0)

      ship.spawn()
      ship.explode()
      return ship

    'should move to `dead` state': (err, ship) ->
      assert.isNull(err)
      assert.isObject(ship)
      assert.strictEqual(ship.state, 'dead')
