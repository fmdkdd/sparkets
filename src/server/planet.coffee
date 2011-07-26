ChangingObject = require('./changingObject').ChangingObject
utils = require '../utils'

class Planet extends ChangingObject
	constructor: (@game, x, y, force) ->
		super()

		@watchChanges 'id'
		@watchChanges 'type'
		@watchChanges 'pos'
		@watchChanges 'color'
		@watchChanges 'boundingRadius'
		@watchChanges 'hitBox' if @game.prefs.debug.sendHitBoxes

		@type = 'planet'
		@pos = {x, y}
		@force = force
		@color = @game.prefs.planet.color

		@boundingRadius = @force
		@hitBox =
			type: 'circle'
			radius: @force
			x: @pos.x
			y: @pos.y

	update: () ->

	move: () ->

	tangible: () ->
		yes

exports.Planet = Planet
