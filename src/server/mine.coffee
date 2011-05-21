ChangingObject = require('./changingObject').ChangingObject
prefs = require './prefs'
utils = require '../utils'

class Mine extends ChangingObject
	constructor: (ship, @id) ->
		super()

		@watchChanges 'type'
		@watchChanges 'pos'
		@watchChanges 'state'
		@watchChanges 'color'
		@watchChanges 'hitRadius'
		@watchChanges 'countdown'
		@watchChanges 'serverDelete'

		@type = 'mine'
		@state = 'inactive'
		@countdown = prefs.mine.states[@state].countdown
		@pos =
			x: ship.pos.x
			y: ship.pos.y
		@color = ship.color
		@explosionRadius = prefs.mine.explosionRadius

		@hitRadius = 0

	tangible: () ->
		@state is 'active' or @state is 'exploding'

	collidesWith: ({pos: {x,y}, hitRadius, type}) ->
		# Distance should wrap around the map, since potentially
		# colliding objects are in the vicinity.

		# Consider the closest object among its images in infinity.
		{w, h} = prefs.server.mapSize

		bestDistance = Infinity
		for j in [-1..1]
			for k in [-1..1]
				ox = x + j * w
				oy = y + k * h
				d = utils.distance(@pos.x, @pos.y, ox, oy)

				if d < bestDistance
					bestDistance = d

		bestDistance < @hitRadius + hitRadius

	nextState: () ->
		@state = prefs.mine.states[@state].next
		@countdown = prefs.mine.states[@state].countdown

	move: () ->
		true

	update: () ->
		@countdown -= prefs.server.timestep if @countdown?

		# The mine is not yet activated.
		switch @state
			when 'inactive'
				@nextState() if @countdown <= 0

			# The mine is ready.
			when 'active'
				++@hitRadius
				@hitRadius = 0 if @hitRadius is prefs.mine.maxDetectionRadius

			# The mine is exploding.
			when 'exploding'
				@hitRadius = @explosionRadius
				@nextState() if @countdown <= 0

			# The explosion is over.
			when 'dead'
				@serverDelete = yes

exports.Mine = Mine
