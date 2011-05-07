utils = require '../utils'

class Planet
	constructor: (x, y, @force) ->
		@type = 'planet'
		@hitRadius = @force
		@pos = {x, y}

	tangible: () ->
		yes

	collidesWith: ({pos: {x,y}, hitRadius}) ->
		utils.distance(@pos.x, @pos.y, x, y) < @hitRadius + hitRadius

exports.Planet = Planet