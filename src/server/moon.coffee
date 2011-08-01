Planet = require('./planet').Planet
utils = require '../utils'

class Moon extends Planet
	constructor: (@game, @planet, force, gap) ->
		# No position yet
		super(@game, 0, 0, force)

		@type = 'moon'
		@flagNextUpdate('type')

		@color = @game.prefs.planet.moonColor
		@flagNextUpdate('color')

		# Polar coordinates
		@dist = @planet.force + gap + force
		@angle = Math.random() * 2*Math.PI

		# Speed increase at each update
		m = @game.prefs.planet.satellitePullMin
		M = @game.prefs.planet.satellitePullMax - m
		pull = m + M * Math.random()
		@speed = pull * @planet.force / (@dist * Math.sqrt(@dist))

		# Random clockwise or counterclockwise direction.
		@speed *= -1 if Math.random() < 0.5

		# Update position once.
		@move()

	move: (step) ->
		@pos.x = @planet.pos.x + @dist * Math.cos(@angle)
		@pos.y = @planet.pos.y + @dist * Math.sin(@angle)

		# XXX: moons always follow the same pattern. Clients should
		# infer that with starting polar coordinates and speed.
		@flagNextUpdate('pos')

		# Update hitbox
		@hitBox.x = @pos.x
		@hitBox.y = @pos.y
		@flagNextUpdate('hitBox.x')
		@flagNextUpdate('hitBox.y')

	update: (step) ->
		@angle += @speed

exports.Moon = Moon
