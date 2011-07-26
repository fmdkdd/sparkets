ChangingObject = require('./changingObject').ChangingObject
utils = require('../utils')

class Shield extends ChangingObject
	constructor: (@id, @game, @ship) ->
		super()

		@watchChanges 'type'
		@watchChanges 'pos'
		@watchChanges 'color'
		@watchChanges 'serverDelete'
		@watchChanges 'boundingRadius'
		@watchChanges 'hitBox'

		@type = 'shield'

		@pos =
			x: ship.pos.x
			y: ship.pos.y

		@color = ship.color
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

		# Follow ship
		@pos.x = @ship.pos.x
		@pos.y = @ship.pos.y
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
				# Delete shield when ship dies.
				if @ship.state isnt 'alive'
					@nextState()
					return

				# Expire shield after a set amount of time.
				@nextState() if @countdown <= 0

			when 'dead'
				@serverDelete = yes

exports.Shield = Shield
