ChangingObject = require('./changingObject').ChangingObject
utils = require('../utils')

class Shield extends ChangingObject
	constructor: (@id, @game, @owner) ->
		super()

		@watchChanges 'type'
		@watchChanges 'pos'
		@watchChanges 'color'
		@watchChanges 'serverDelete'
		@watchChanges 'boundingRadius'
		@watchChanges 'hitBox' if @game.prefs.debug.sendHitBoxes

		@type = 'shield'

		@pos =
			x: owner.pos.x
			y: owner.pos.y

		@color = owner.color
		@force = @game.prefs.shield.radius

		@state = 'active'
		@countdown = @game.prefs.shield.states[@state].countdown

		@boundingRadius = @force
		@hitBox =
			type: 'circle'
			radius: @force
			x: @pos.x
			y: @pos.y

	cancel: () ->
		@serverDelete = yes

	tangible: () ->
		yes

	move: () ->
		return if @state isnt 'active'

		# Follow owner
		@pos.x = @owner.pos.x
		@pos.y = @owner.pos.y
		@changed 'pos'

		# Update hitbox
		@hitBox.x = @pos.x
		@hitBox.y = @pos.y
		@changed 'hitBox'

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

exports.Shield = Shield
