ChangingObject = require('./changingObject').ChangingObject
utils = require '../utils'

class Mine extends ChangingObject
	constructor: (@id, @game, @owner, @pos) ->
		super()

		# Send these properties to new players.
		@flagFullUpdate('type')
		@flagFullUpdate('ownerId')
		@flagFullUpdate('pos')
		@flagFullUpdate('state')
		@flagFullUpdate('serverDelete')
		@flagFullUpdate('boundingRadius')
		@flagFullUpdate('hitBox') if @game.prefs.debug.sendHitBoxes

		@type = 'mine'
		@flagNextUpdate('type')

		# Transmit owner id to clients.
		@ownerId = @owner.id
		@flagNextUpdate('ownerId')

		# Initial state.
		@state = 'inactive'
		@countdown = @game.prefs.mine.states[@state].countdown

		@flagNextUpdate('state')

		# Static position.
		@pos =
			x: pos.x
			y: pos.y

		@flagNextUpdate('pos')

		# Hit box is a circle with static position and varying radius.
		@boundingRadius = 5
		@hitBox =
			type: 'circle'
			radius: @boundingRadius
			x: @pos.x
			y: @pos.y

		@flagNextUpdate('boundingRadius')
		@flagNextUpdate('hitBox') if @game.prefs.debug.sendHitBoxes

	tangible: () ->
		@state is 'active' or @state is 'exploding'

	nextState: () ->
		@state = @game.prefs.mine.states[@state].next
		@countdown = @game.prefs.mine.states[@state].countdown

		@flagNextUpdate('state')

	setState: (state) ->
		if @game.prefs.mine.states[state]?
			@flagNextUpdate('state') unless @state is state

			@state = state
			@countdown = @game.prefs.mine.states[state].countdown

	move: (step) ->
		# Not moving!

	update: (step) ->
		if @countdown?
			@countdown -= @game.prefs.timestep * step
			@nextState() if @countdown <= 0

		switch @state
			# The mine is active.
			when 'active'
				# FIXME: slower in powersave mode.
				@boundingRadius += @game.prefs.mine.waveSpeed
				if @boundingRadius >= @game.prefs.mine.maxDetectionRadius
					@boundingRadius = @game.prefs.mine.minDetectionRadius

				@flagNextUpdate('boundingRadius')

			# The mine is exploding.
			when 'exploding'
				@boundingRadius = @game.prefs.mine.explosionRadius

				@flagNextUpdate('boundingRadius')

			# The explosion is over.
			when 'dead'
				@serverDelete = yes

				@flagNextUpdate('serverDelete')

		# Update hit box radius.
		@hitBox.radius = @boundingRadius

		@flagNextUpdate('hitBox.radius') if @game.prefs.debug.sendHitBoxes

	explode: () ->
		@setState 'exploding'

		@game.events.push
			type: 'mine exploded'
			id: @id

exports.Mine = Mine
