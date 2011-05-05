ChangingObject = require './changingObject'
globals = require './server'
prefs = require './prefs'
utils = require '../utils'

class Mine extends ChangingObject.ChangingObject
	constructor: (ship, @id) ->
		super()

		@watchChanges 'state'
		@watchChanges 'color'
		@watchChanges 'radius'
		@watchChanges 'explosionRadius'
		@watchChanges 'countdown'
		@changed 'pos'

		@state = 'inactive'
		@playerId = ship.id
		@pos =
			x: ship.pos.x
			y: ship.pos.y
		@color = ship.color
		@radius = prefs.mine.radius
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

			for id, ship of globals.ships
				if not ship.isDead() and
						not ship.isExploding() and
						-@radius < @pos.x - ship.pos.x < @radius and
						-@radius < @pos.y - ship.pos.y < @radius
					@nextState()

			for b in globals.bullets
				if not b.dead and
						-@radius < @pos.x - b.pos.x < @radius and
						-@radius < @pos.y - b.pos.y < @radius
					@nextState()

		# The mine is exploding.
		else if @state is 'exploding'
			@nextState() if @countdown <= 0

			for id, ship of globals.ships
				if not ship.isDead() and
						not ship.isExploding() and
						-@explosionRadius < @pos.x - ship.pos.x < @explosionRadius and
						-@explosionRadius < @pos.y - ship.pos.y < @explosionRadius
					ship.explode()

		# The explosion is over.
		else if @state is 'dead'
			delete globals.mines[@id]

exports.Mine = Mine
