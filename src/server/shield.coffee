ChangingObject = require('./changingObject').ChangingObject
utils = require('../utils')

class Shield extends ChangingObject
	constructor: (@id, @game, @owner) ->
		super()

		# Send these properties to new players.
		@flagFullUpdate('type')
		@flagFullUpdate('ownerId')
		@flagFullUpdate('serverDelete')
		@flagFullUpdate('boundingRadius')
		@flagFullUpdate('hitBox') if @game.prefs.debug.sendHitBoxes

		@type = 'shield'
		@flagNextUpdate('type')

		# ID number of owner ship for clients.
		@ownerId = @owner.id
		@flagNextUpdate('ownerId')

		# Follow owner ship.
		@pos = @owner.pos

		# Initial state.
		@state = 'active'
		@countdown = @game.prefs.shield.states[@state].countdown

		# FIXME: uncouple bounding radius and force, same as planet.
		@force = @game.prefs.shield.radius
		@boundingRadius = @force

		@flagNextUpdate('boundingRadius')

		# Hit box is a circle of fixed radius centered on the ship.
		@hitBox =
			type: 'circle'
			radius: @force
			x: @pos.x
			y: @pos.y

	cancel: () ->
		@serverDelete = yes

		@flagNextUpdate('serverDelete')

	tangible: () ->
		yes

	move: (step) ->
		return if @state isnt 'active'

		# Our position is the ship's, no need to update it.

		# Hit box update is still necessary.
		@hitBox.x = @pos.x
		@hitBox.y = @pos.y

		if @game.prefs.debug.sendHitBoxes
			@flagNextUpdate('hitBox.x')
			@flagNextUpdate('hitBox.y')

	nextState: () ->
		@state = @game.prefs.shield.states[@state].next
		@countdown = @game.prefs.shield.states[@state].countdown

	update: (step) ->
		@countdown -= @game.prefs.timestep * step if @countdown?

		switch @state
			when 'active'
				# Delete shield when owner dies.
				if @owner.state isnt 'alive'
					@nextState()
					return

				# Expire shield after a set amount of time.
				@nextState() if @countdown <= 0

			when 'dead'
				@serverDelete = yes

				@flagNextUpdate('serverDelete')

exports.Shield = Shield
