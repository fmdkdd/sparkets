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

		@hitRadius = 0
		@collisions = []

	collidesWith: ({pos: {x,y}, hitRadius}) ->
		@state isnt 'inactive' and @state isnt 'dead' and
			utils.distance(@pos.x, @pos.y, x, y) < @hitRadius + hitRadius

	nextState: () ->
		@state = prefs.mine.states[@state].next
		@countdown = prefs.mine.states[@state].countdown

	explode: () ->
		@state = 'exploding'
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
				@hitRadius = @detectionRadius
				@nextState() if @collidedWith 'ship', 'bullet'

				# Only exploding mines trigger other mines.
				@nextState() if @collisions.some( ({type, state}) ->
					type is 'mine' and state is 'exploding' )

			# The mine is exploding.
			when 'exploding'
				@hitRadius = @explosionRadius
				@nextState() if @countdown <= 0

			# The explosion is over.
			when 'dead'
				@deleteMe = yes

exports.Mine = Mine
