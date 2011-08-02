server = require './server'
Ship = require('./ship').Ship

class Player
	constructor: (@id, @game) ->
		@keys = {}
		@ship = null

	createShip: (id) ->
		@ship = new Ship(id, @game, @id, @name, @color)

	keyDown: (key) ->
		@keys[key] = on

	keyUp: (key) ->
		@keys[key] = off

		# Fire the bullet or respawn if the spacebar or A is released.
		if key is 32 or key is 65
			if @ship.state is 'ready'
				@ship.spawn()
			else
				@ship.fire()

		if key is 38
			@ship.stopEngine()

		# Z : use bonus.
		if key is 90
			@ship.useBonus()

	update: (step) ->
		return if not @ship? or @ship.state in ['dead', 'ready']

		# Left arrow : rotate to the left.
		@ship.turnLeft(step) if @keys[37] is on

		# Right arrow : rotate to the right.
		@ship.turnRight(step) if @keys[39] is on

		# Up arrow : thrust forward.
		@ship.ahead(step) if @keys[38] is on

		# Spacebar/A : charge the bullet.
		@ship.chargeFire(step) if @keys[32] is on or @keys[65] is on

	changePrefs: (name, color) ->
		if name?
			@name = name
			@ship.name = name if @ship?

		if color?
			@color = color
			@ship.color = color if @ship?

exports.Player = Player
