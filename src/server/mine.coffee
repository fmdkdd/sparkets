class Mine
	constructor: (ship) ->
		@state = 0

		@playerId = ship.id
		@pos =
			x: ship.pos.x
			y: ship.pos.y
		@color = ship.color
		@radius = 10
		@explosionRadius = null

		@countdown = 1000
		@lastUpdate = (new Date).getTime()
		
	activate: () ->
		@state = 1

	explode: () ->
		@state = 2

		@countdown = 1000
		@explosionRadius = 0

	die: () ->
		@state = 3

	update: () ->
		now = (new Date).getTime()
		diff =  now - @lastUpdate

		# The mine is not yet activated.
		if @state == 0
			@countdown -= diff
			@activate() if @countdown <= 0

		# The mine is ready.
		else if @state == 1

			for id, ship of ships
				if not ship.isDead() and
						not ship.isExploding() and
						-10 < @pos.x - ship.pos.x < 10 and
						-10 < @pos.y - ship.pos.y < 10
					@explode()

		# The mine is exploding.
		else if @state == 2

			@countdown -= diff
			++@explosionRadius

			@die() if @countdown <= 0

		@lastUpdate = now
