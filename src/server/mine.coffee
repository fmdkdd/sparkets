ChangingObject = require('./changingObject').ChangingObject
utils = require '../utils'

class Mine extends ChangingObject
	constructor: (@id, @game, @owner, @pos) ->
		super()

		@watchChanges 'type'
		@watchChanges 'pos'
		@watchChanges 'state'
		@watchChanges 'color'
		@watchChanges 'serverDelete'
		@watchChanges 'boundingRadius'
		@watchChanges 'hitBox'

		@type = 'mine'

		@state = 'inactive'
		@countdown = @game.prefs.mine.states[@state].countdown

		@pos =
			x: pos.x
			y: pos.y

		@color = @owner.color

		@explosionRadius = @game.prefs.mine.explosionRadius

		@boundingRadius = 0
		@hitBox =
			type: 'circle'
			radius: @boundingRadius
			x: @pos.x
			y: @pos.y

	tangible: () ->
		@state is 'active' or @state is 'exploding'

	nextState: () ->
		@state = @game.prefs.mine.states[@state].next
		@countdown = @game.prefs.mine.states[@state].countdown

	setState: (state) ->
		if @game.prefs.mine.states[state]?
			@state = state
			@countdown = @game.prefs.mine.states[state].countdown

	move: () ->

	update: () ->
		if @countdown?
			@countdown -= @game.prefs.timestep
			@nextState() if @countdown <= 0

		switch @state

			# The mine is active.
			when 'active'
				@boundingRadius += @game.prefs.mine.waveSpeed
				if @boundingRadius >= @game.prefs.mine.maxDetectionRadius
					@boundingRadius = @game.prefs.mine.minDetectionRadius

			# The mine is exploding.
			when 'exploding'
				@boundingRadius = @explosionRadius

			# The explosion is over.
			when 'dead'
				@serverDelete = yes

		# Update hitBox radius
		@hitBox.radius = @boundingRadius
		@changed 'hitBox'

	explode: () ->
		@setState 'exploding'

		@game.events.push
			type: 'mine exploded'
			id: @id

exports.Mine = Mine
