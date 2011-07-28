ChangingObject = require('./changingObject').ChangingObject
utils = require('../utils')

class Shield extends ChangingObject
	constructor: (@id, @game, @owner) ->
		super()

		# Send these properties to new players.
		@flagFullUpdate('type')
		@flagFullUpdate('color')
		@flagFullUpdate('serverDelete')
		@flagFullUpdate('boundingRadius')
		@flagFullUpdate('hitBox') if @game.prefs.debug.sendHitBoxes

		@type = 'shield'
		@flagNextUpdate('type')

		# Follow owner ship.
		@pos = @owner.pos

		# Same color as owner ship.
		@color = owner.color
		@force = @game.prefs.shield.radius

		# Initial state.
		@state = 'active'
		@countdown = @game.prefs.shield.states[@state].countdown

		# FIXME: uncouple bounding radius and force, same as planet.
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

	move: () ->
		return if @state isnt 'active'

		# Our position is the ship's, no need to update it.

		# Hit box update is still necessary.
		@hitBox.x = @pos.x
		@hitBox.y = @pos.y
		@flagNextUpdate('hitBox') if @game.prefs.debug.sendHitBoxes

	nextState: () ->
		@state = @game.prefs.shield.states[@state].next
		@countdown = @game.prefs.shield.states[@state].countdown

	update: () ->
		@countdown -= @game.prefs.timestep if @countdown?

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
