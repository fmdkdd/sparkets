ChangingObject = require('./changingObject').ChangingObject
utils = require '../utils'

class Planet extends ChangingObject
	constructor: (@game, x, y, force) ->
		super()

		@watchChanges 'id'
		@watchChanges 'type'
		@watchChanges 'pos'
		@watchChanges 'force'
		@watchChanges 'hitRadius'
		@watchChanges 'color'

		@type = 'planet'
		@pos = {x, y}
		@hitRadius = @force = force
		@color = @game.prefs.planet.color

	update: () ->

	move: () ->

	tangible: () ->
		yes

	collidesWith: ({pos: {x,y}, hitRadius}, offset = {x:0, y:0}) ->
		x += offset.x
		y += offset.y
		utils.distance(@pos.x, @pos.y, x, y) < @hitRadius + hitRadius

exports.Planet = Planet
