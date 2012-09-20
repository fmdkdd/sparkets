ChangingObject = require('./changingObject').ChangingObject
utils = require '../utils'

class Planet extends ChangingObject
	constructor: (@game, x, y, force) ->
		super()

		# Send these properties to new players.
		@flagFullUpdate('type')
		@flagFullUpdate('pos')
		@flagFullUpdate('force')
		@flagFullUpdate('color')
		if @game.prefs.debug.sendHitBoxes
			@flagFullUpdate('id')
			@flagFullUpdate('boundingBox')
			@flagFullUpdate('hitBox')

		@type = 'planet'
		@flagNextUpdate('type')

		# Static position.
		@pos = {x, y}

		@flagNextUpdate('pos')

		# Radius of planet.
		@force = force

		@flagNextUpdate('force')

		# Static bounding box with force as radius.
		@boundingBox =
			x: @pos.x
			y: @pos.y
			radius: @force

		# Circle hit box with static position and radius.
		@hitBox =
			type: 'circle'
			radius: @force
			x: @pos.x
			y: @pos.y

		if @game.prefs.debug.sendHitBoxes
			@flagNextUpdate('boundingBox')
			@flagNextUpdate('hitBox')

		@color = [360*Math.random(), 10 + Math.random()*30, 61]
		@flagNextUpdate('color')

	update: (step) ->
		# Nothing to update

	move: (step) ->
		# Not moving!

	tangible: () ->
		yes

exports.Planet = Planet
