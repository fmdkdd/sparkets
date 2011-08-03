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
		@flagFullUpdate('radius')
		@flagFullUpdate('serverDelete')
		if @game.prefs.debug.sendHitBoxes
			@flagFullUpdate('boundingBox')
			@flagFullUpdate('hitBox')

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
		@radius = 0
		@flagNextUpdate('radius')

		@boundingBox =
			x: @pos.x
			y: @pos.y
			radius: @radius

		@hitBox =
			type: 'circle'
			x: @pos.x
			y: @pos.y
			radius: @radius

		if @game.prefs.debug.sendHitBoxes
			@flagNextUpdate('boundingBox')
			@flagNextUpdate('hitBox')

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
		switch @state
			# The mine is active.
			when 'active'
				# FIXME: slower in powersave mode.
				@radius += @game.prefs.mine.waveSpeed
				if @radius >= @game.prefs.mine.maxDetectionRadius
					@radius = @game.prefs.mine.minDetectionRadius

				@flagNextUpdate('radius')

			# The mine is exploding.
			when 'exploding'
				@radius = @game.prefs.mine.explosionRadius

				@flagNextUpdate('radius')

		# Update hit box radius.
		@boundingBox.radius = @hitBox.radius = @radius

		if @game.prefs.debug.sendHitBoxes
			@flagNextUpdate('boundingBox.radius')
			@flagNextUpdate('hitBox.radius')

	update: (step) ->
		if @countdown?
			@countdown -= @game.prefs.timestep * step
			@nextState() if @countdown <= 0

		switch @state
			# The explosion is over.
			when 'dead'
				@serverDelete = yes

				@flagNextUpdate('serverDelete')

	explode: () ->
		@setState 'exploding'

		@game.events.push
			type: 'mine exploded'
			id: @id

exports.Mine = Mine
