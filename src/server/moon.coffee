Planet = require('./planet').Planet
utils = require '../utils'

class Moon extends Planet
	constructor: (@game, @planet, force, gap) ->
		# No position yet
		super(@game, 0, 0, force)

		@type = 'moon'
		@flagNextUpdate('type')

		@color = [360*Math.random(), 60 + Math.random()*30, 50]
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

		# Only send polar coordinates to clients, not position.
		@flagFullUpdate('planet.pos')
		@flagFullUpdate('angle')
		@flagFullUpdate('dist')
		@flagFullUpdate('speed')

		# Update position once.
		@move()

	move: (step) ->
		@pos.x = @planet.pos.x + @dist * Math.cos(@angle)
		@pos.y = @planet.pos.y + @dist * Math.sin(@angle)

		# Update bounding box position.
		@boundingBox.x = @pos.x
		@boundingBox.y = @pos.y

		if @game.prefs.debug.sendHitBoxes
			@flagNextUpdate('boundingBox.x')
			@flagNextUpdate('boundingBox.y')

		# Update hitbox
		@hitBox.x = @pos.x
		@hitBox.y = @pos.y

		if @game.prefs.debug.sendHitBoxes
			@flagNextUpdate('hitBox.x')
			@flagNextUpdate('hitBox.y')

	update: (step) ->
		# FIXME: slower in power save.
		@angle += @speed

		# We could send this less frequently and let the client
		# interpolate in the meantime. Beware of floating point drift
		# though.
		@flagNextUpdate('angle')

exports.Moon = Moon
