ChangingObject = require './changingObject'
globals = require './server'
prefs = require './prefs'
utils = require '../utils'

class Mine extends ChangingObject.ChangingObject
	constructor: (ship, @id) ->
		super()

		@watchChanges 'state'
		@watchChanges 'color'
		@watchChanges 'modelRadius'
		@watchChanges 'detectionRadius'
		@watchChanges 'explosionRadius'
		@watchChanges 'countdown'
		@changed 'pos'

		@state = 'inactive'
		@playerId = ship.id
		@pos =
			x: ship.pos.x
			y: ship.pos.y
		@color = ship.color
		@modelRadius = prefs.mine.modelRadius
		@detectionRadius = prefs.mine.detectionRadius
		@explosionRadius = prefs.mine.explosionRadius
		@countdown = prefs.mine.states[@state].countdown

	nextState: () ->
		@state = prefs.mine.states[@state].next
		@countdown = prefs.mine.states[@state].countdown

	update: () ->
		@countdown -= prefs.server.timestep if @countdown?

		# The mine is not yet activated.
		if @state is 'inactive'
			@nextState() if @countdown <= 0

		# The mine is ready.
		else if @state is 'active'
			r = @detectionRadius

			for id, ship of globals.ships
				if not ship.isDead() and
						not ship.isExploding() and
						-r < @pos.x - ship.pos.x < r and
						-r < @pos.y - ship.pos.y < r
					@nextState()

			for b in globals.bullets
				if not b.dead and
						-r < @pos.x - b.pos.x < r and
						-r < @pos.y - b.pos.y < r
					@nextState()

		# The mine is exploding.
		else if @state is 'exploding'
			@nextState() if @countdown <= 0

			r = @explosionRadius

			for id, ship of globals.ships
				if not ship.isDead() and
						not ship.isExploding() and
						-r < @pos.x - ship.pos.x < r and
						-r < @pos.y - ship.pos.y < r
					ship.explode()

		# The explosion is over.
		else if @state is 'dead'
			delete globals.mines[@id]

exports.Mine = Mine
