ChangingObject = require './changingObject'
globals = require './server'
utils = require '../utils'

class Mine extends ChangingObject.ChangingObject
	constructor: (ship) ->
		super()

		@state = 0

		@playerId = ship.id
		@pos =
			x: ship.pos.x
			y: ship.pos.y
		@color = ship.color
		@radius = globals.mineRadius
		@explosionRadius = globals.mineExplosionRadius

		@countdown = 500
		@lastUpdate = (new Date).getTime()
		
	activate: () ->
		@state = 1

	explode: () ->
		@state = 2

		@countdown = 500

	die: () ->
		@state = 3

	update: () ->
		now = (new Date).getTime() # (globalization of 'now' would be nice)
		diff =  now - @lastUpdate

		# The mine is not yet activated.
		if @state is 0
			@countdown -= diff
			@activate() if @countdown <= 0

		# The mine is ready.
		else if @state is 1

			for id, ship of globals.ships
				if not ship.isDead() and
						not ship.isExploding() and
						-@radius < @pos.x - ship.pos.x < @radius and
						-@radius < @pos.y - ship.pos.y < @radius
					@explode()

		# The mine is exploding.
		else if @state is 2
			@countdown -= diff

			@die() if @countdown <= 0

			for id, ship of globals.ships
				if not ship.isDead() and
						not ship.isExploding() and
						-@explosionRadius < @pos.x - ship.pos.x < @explosionRadius and
						-@explosionRadius < @pos.y - ship.pos.y < @explosionRadius
					ship.explode()

		@lastUpdate = now

exports.Mine = Mine
