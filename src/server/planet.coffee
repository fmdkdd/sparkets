class Planet
	constructor: (x, y, @force) ->
		@type = 'planet'
		@pos = {x, y}

exports.Planet = Planet