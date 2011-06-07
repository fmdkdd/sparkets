Planet = require('./planet').Planet
prefs = require './prefs'
utils = require '../utils'

class Moon extends Planet
	constructor: (@planet, force, gap) ->
		# No position yet
		super(0, 0, force)

		@type = 'moon'

		# Polar coordinates
		@dist = @planet.force + gap + force
		@angle = Math.random() * 2*Math.PI

		# Speed increase at each update
		m = prefs.planet.satellitePullMin
		M = prefs.planet.satellitePullMax - m
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
