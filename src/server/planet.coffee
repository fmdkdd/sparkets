ChangingObject = require('./changingObject').ChangingObject
utils = require '../utils'

class Planet extends ChangingObject
	constructor: (x, y, force) ->
		super()

		@watchChanges 'type'
		@watchChanges 'pos'
		@watchChanges 'force'

		@type = 'planet'
		@hitRadius = @force = force
		@pos = {x, y}

	update: () ->

	move: () ->

	tangible: () ->
		yes

	collidesWith: ({pos: {x,y}, hitRadius}) ->
		utils.distance(@pos.x, @pos.y, x, y) < @hitRadius + hitRadius

exports.Planet = Planet