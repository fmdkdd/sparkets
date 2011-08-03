server = require './server'
Ship = require('./ship').Ship

class Player
	constructor: (@id, @game) ->
		@keysDown = {}
		@keysUp = {}
		@ship = null

	createShip: (id) ->
		@ship = new Ship(id, @game, @id, @name, @color)

	keyDown: (key) ->
		@keysDown[key] = on

	keyUp: (key) ->
		@keysDown[key] = off
		@keysUp[key] = on

	update: (step) ->
		# Fire the bullet or respawn if the spacebar or A is released.
		if @keysUp[32] or @keysUp[65]
			if @ship.state is 'ready'
				@ship.spawn()
			else
				@ship.fire()

		if @keysUp[38]
			@ship.stopEngine()

		# Z : use bonus.
		if @keysUp[90]
			@ship.useBonus()

		@keysUp = {}

		return if not @ship? or @ship.state in ['dead', 'ready']

		# Left arrow : rotate to the left.
		@ship.turnLeft(step) if @keysDown[37] is on

		# Right arrow : rotate to the right.
		@ship.turnRight(step) if @keysDown[39] is on

		# Up arrow : thrust forward.
		@ship.ahead(step) if @keysDown[38] is on

		# Spacebar/A : charge the bullet.
		@ship.chargeFire(step) if @keysDown[32] is on or @keysDown[65] is on

	changePrefs: (name, color) ->
		if name?
			@name = name
			@ship.name = name if @ship?

		if color?
			@color = color
			@ship.color = color if @ship?


exports.Player = Player
