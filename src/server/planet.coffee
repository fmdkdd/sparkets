ChangingObject = require('./changingObject').ChangingObject
utils = require '../utils'

class Planet extends ChangingObject
	constructor: (@game, x, y, force) ->
		super()

		# Send these properties to new players.
		@flagFullUpdate('type')
		@flagFullUpdate('pos')
		@flagFullUpdate('color')
		@flagFullUpdate('boundingRadius')
		@flagFullUpdate('id') if @game.prefs.debug.sendHitBoxes
		@flagFullUpdate('hitBox') if @game.prefs.debug.sendHitBoxes

		@type = 'planet'
		@flagNextUpdate('type')

		# Static position.
		@pos = {x, y}

		@flagNextUpdate('pos')

		# Radius of planet.
		@force = force

		# XXX: client relies only on bounding radius to draw ... we
		# should uncouple this.
		@boundingRadius = @force

		@flagNextUpdate('boundingRadius')

		# Circle hit box with static position and radius.
		@hitBox =
			type: 'circle'
			radius: @force
			x: @pos.x
			y: @pos.y

		@flagNextUpdate('hitBox') if @game.prefs.debug.sendHitBoxes

		# Same color for all planets.
		@color = @game.prefs.planet.color

		@flagNextUpdate('color')

	update: (step) ->
		# Nothing to update

	move: (step) ->
		# Not moving!

	tangible: () ->
		yes

exports.Planet = Planet
