ChangingObject = require('./changingObject').ChangingObject
utils = require '../utils'

class Planet extends ChangingObject
	constructor: (x, y, force) ->
		super()

		@watchChanges 'id'
		@watchChanges 'type'
		@watchChanges 'pos'
		@watchChanges 'force'
		@watchChanges 'hitRadius'

		@type = 'planet'
		@hitRadius = @force = force
		@pos = {x, y}

	update: () ->

	move: () ->

	tangible: () ->
		yes

	collidesWith: ({pos: {x,y}, hitRadius}, offset = {x:0, y:0}) ->
		x += offset.x
		y += offset.y
		utils.distance(@pos.x, @pos.y, x, y) < @hitRadius + hitRadius

exports.Planet = Planet