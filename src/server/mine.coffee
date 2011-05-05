ChangingObject = require './changingObject'
globals = require './server'
utils = require '../utils'

class Mine extends ChangingObject.ChangingObject
	constructor: (ship) ->
		super()

		@state = 'inactive'
		@playerId = ship.id
		@pos =
			x: ship.pos.x
			y: ship.pos.y
		@color = ship.color
		@radius = globals.mineRadius
		@explosionRadius = globals.mineExplosionRadius

		@countdown = globals.mineStates[@state].countdown
		@lastUpdate = (new Date).getTime()
		
	nextState: () ->
		@state = globals.mineStates[@state].next
		@countdown = globals.mineStates[@state].countdown

	update: () ->
		console.log @state
		now = (new Date).getTime() # (globalization of 'now' would be nice)
		diff =  now - @lastUpdate

		# The mine is not yet activated.
		if @state is 'inactive'
			@countdown -= diff
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
			@countdown -= diff
			@nextState() if @countdown <= 0

			for id, ship of globals.ships
				if not ship.isDead() and
						not ship.isExploding() and
						-@explosionRadius < @pos.x - ship.pos.x < @explosionRadius and
						-@explosionRadius < @pos.y - ship.pos.y < @explosionRadius
					ship.explode()

		@lastUpdate = now

exports.Mine = Mine
