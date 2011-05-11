server = require './server'
prefs = require './prefs'
Ship = require './ship'

class Player
	constructor: (@id) ->
		@keys = {}
		@ship = null

	createShip: (id) ->
		@ship = new Ship.Ship(id)

	keyDown: (key) ->
		@keys[key] = on

	keyUp: (key) ->
		@keys[key] = off

		# Fire the bullet or respawn if the spacebar is released.
		if key is 32 or key is 65
			if @ship.isDead()
				@ship.spawn()
			else
				@ship.fire()

		if key is 38
			@ship.thrust = false

		# Z : drop a mine.
		if key is 90
			@ship.dropMine()

		# X: 88 miles/h
		if key is 88
			@ship.boost = prefs.ship.boostFactor

	update: () ->
		return if not @ship?

		# Left arrow : rotate to the left.
		@ship.turnLeft() if @keys[37] is on

		# Right arrow : rotate to the right.
		@ship.turnRight() if @keys[39] is on

		# Up arrow : thrust forward.
		@ship.ahead() if @keys[38] is on

		# Spacebar/A : charge the bullet.
		@ship.chargeFire() if @keys[32] is on or @keys[65] is on

exports.Player = Player