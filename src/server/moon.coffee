Planet = require('./planet').Planet
prefs = require './prefs'
utils = require '../utils'

class Moon extends Planet
	constructor: (px, py, pforce, force, gap) ->
		# No position yet
		super(0, 0, force)

		@type = 'moon'

		# Polar coordinates
		@origin = {x: px, y: py}
		@dist = pforce + gap + force
		@angle = Math.random() * 2*Math.PI

		# Speed increase at each update
		m = prefs.planet.satellitePullMin
		M = prefs.planet.satellitePullMax - m
		pull = m + M * Math.random()
		@speed = pull * pforce / (@dist * Math.sqrt(@dist))

		# Update position
		@move()

	move: () ->
		@pos.x = @origin.x + @dist * Math.cos(@angle)
		@pos.y = @origin.y + @dist * Math.sin(@angle)

		@changed 'pos'

	update: () ->
		@angle += @speed

exports.Moon = Moon