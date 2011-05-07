ChangingObject = require './changingObject'
globals = require './server'
prefs = require './prefs'
utils = require '../utils'

class Mine extends ChangingObject.ChangingObject
	constructor: (ship, @id) ->
		super()

		@watchChanges 'type'
		@watchChanges 'pos'
		@watchChanges 'state'
		@watchChanges 'color'
		@watchChanges 'modelRadius'
		@watchChanges 'detectionRadius'
		@watchChanges 'explosionRadius'
		@watchChanges 'countdown'

		@type = 'mine'
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

	explode: () ->
		@state = 'exploding'
		@countdown = prefs.mine.states[@state].countdown

	update: () ->
		@countdown -= prefs.server.timestep if @countdown?

		# The mine is not yet activated.
		switch @state
			when 'inactive'
				@nextState() if @countdown <= 0

		# The mine is ready.
			when 'active'
				r = @detectionRadius

				for id, ship of globals.ships
					if not ship.isDead() and
							not ship.isExploding() and
							-r < @pos.x - ship.pos.x < r and
							-r < @pos.y - ship.pos.y < r
						@nextState()

				for id, bullet of globals.bullets
					if not bullet.dead and
							-r < @pos.x - bullet.pos.x < r and
							-r < @pos.y - bullet.pos.y < r
						@nextState()

			# The mine is exploding.
			when 'exploding'
				@nextState() if @countdown <= 0

				r = @explosionRadius

				for id, ship of globals.ships
					if not ship.isDead() and
							not ship.isExploding() and
							-r < @pos.x - ship.pos.x < r and
							-r < @pos.y - ship.pos.y < r
						ship.explode()

				for id, mine of globals.mines
					if mine.id isnt @id and mine.state is 'active'
						radii = @explosionRadius + mine.detectionRadius
						dist = utils.distance(@pos.x, @pos.y, mine.pos.x, mine.pos.y)
						mine.explode() if dist < radii

			# The explosion is over.
			when 'dead'
				@deleteMe = yes

exports.Mine = Mine
