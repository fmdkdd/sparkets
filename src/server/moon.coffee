Planet = require('./planet').Planet
utils = require '../utils'

class Moon extends Planet
	constructor: (@planet, force, gap, @game) ->
		# No position yet
		super(0, 0, force)

		@type = 'moon'

		# Polar coordinates
		@dist = @planet.force + gap + force
		@angle = Math.random() * 2*Math.PI

		# Speed increase at each update
		m = @game.prefs.planet.satellitePullMin
		M = @game.prefs.planet.satellitePullMax - m
		pull = m + M * Math.random()
		@speed = pull * @planet.force / (@dist * Math.sqrt(@dist))
		@speed *= -1 if Math.random() < 0.5

		# Update position
		@move()

	move: () ->
		@pos.x = @planet.pos.x + @dist * Math.cos(@angle)
		@pos.y = @planet.pos.y + @dist * Math.sin(@angle)

		@changed 'pos'

	update: () ->
		@angle += @speed

exports.Moon = Moon
