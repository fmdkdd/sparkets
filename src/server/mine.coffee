ChangingObject = require('./changingObject').ChangingObject
utils = require '../utils'

class Mine extends ChangingObject
	constructor: (@owner, @pos, @id, @game) ->
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
		@countdown = @game.prefs.mine.states[@state].countdown
		@pos =
			x: pos.x
			y: pos.y
		@color = @owner.color
		@explosionRadius = @game.prefs.mine.explosionRadius

		@hitRadius = 0

	tangible: () ->
		@state is 'active' or @state is 'exploding'

	collidesWith: ({pos: {x,y}, hitRadius, type}, offset = {x:0, y:0}) ->
		x += offset.x
		y += offset.y
		utils.distance(@pos.x, @pos.y, x, y) < @hitRadius + hitRadius

	nextState: () ->
		@state = @game.prefs.mine.states[@state].next
		@countdown = @game.prefs.mine.states[@state].countdown

	setState: (state) ->
		if @game.prefs.mine.states[state]?
			@state = state
			@countdown = @game.prefs.mine.states[state].countdown

	move: () ->
		true

	update: () ->
		if @countdown?
			@countdown -= @game.prefs.timestep
			@nextState() if @countdown <= 0

		# The mine is not yet activated.
		switch @state

			# The mine is active.
			when 'active'
				@hitRadius += @game.prefs.mine.waveSpeed
				if @hitRadius >= @game.prefs.mine.maxDetectionRadius
					@hitRadius = @game.prefs.mine.minDetectionRadius

			# The mine is exploding.
			when 'exploding'
				@hitRadius = @explosionRadius

			# The explosion is over.
			when 'dead'
				@serverDelete = yes

	explode: () ->
		@setState 'exploding'

		@game.events.push
			type: 'mine exploded'
			id: @id

exports.Mine = Mine
