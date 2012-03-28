ChangingObject = require('./changingObject').ChangingObject
utils = require '../utils'

class Grenade extends ChangingObject
	constructor: (@id, @game, @owner, @pos, @vel, @childrenCount) ->
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

		@type = 'grenade'
		@flagNextUpdate('type')

		# Transmit owner id to clients.
		@ownerId = @owner.id
		@flagNextUpdate('ownerId')

		# Initial state.
		@state = 'active'
		@countdown = @game.prefs.grenade.states[@state].countdown
		@flagNextUpdate('state')

		delayVar = @game.prefs.grenade.explosionDelayVariation
		@countdown += Math.random() * delayVar - delayVar / 2

		@pos =
			x: pos.x
			y: pos.y
		@flagNextUpdate('pos')

		@initialVel = {x: @vel.x, y: @vel.y}

		# Hit box is a circle with static position and varying radius.
		@radius = 5
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
		@state = @game.prefs.grenade.states[@state].next
		@countdown = @game.prefs.grenade.states[@state].countdown

		@flagNextUpdate('state')

	setState: (state) ->
		if @game.prefs.grenade.states[state]?
			@flagNextUpdate('state') unless @state is state

			@state = state
			@countdown = @game.prefs.grenade.states[state].countdown

	move: (step) ->

		if @vel.x isnt 0 and @vel.y isnt 0
			@pos.x += @vel.x
			@pos.y += @vel.y
			@flagNextUpdate('pos')

		@vel = utils.vec.times(@vel, 0.95)

		switch @state

			# The grenade is exploding.
			when 'exploding'
				@radius = @game.prefs.grenade.explosionRadius
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

			# Spawn new grenades.
			when 'fragmenting'
				if @childrenCount > 0 then @fragment()
				@explode()

			# The explosion is over.
			when 'dead'
				@serverDelete = yes
				@flagNextUpdate('serverDelete')

	fragment: () ->
		offset = @game.prefs.grenade.fragmentationOffset
		halfOffset = offset / 2

		for i in [0..@childrenCount]
			@game.newGameObject (id) =>
				dropPos = {x: @pos.x, y: @pos.y}

				if(utils.vec.length(@initialVel) is 0)
					vel = utils.vec.unit({x: Math.random() - 0.5, y: Math.random() - 0.5})
				else
					vel = utils.vec.rotate(@initialVel, Math.random() * Math.PI - Math.PI / 2)
					vel = utils.vec.unit(vel)

				vel = utils.vec.times(vel, 3 + Math.random() * 2 - 1)

				@game.grenades[id] = new Grenade(id, @game, @owner, dropPos, vel, @childrenCount - 1)

		@setState 'dead'

	explode: () ->
		@setState 'exploding'

		@game.events.push
			type: 'mine exploded'
			id: @id

exports.Grenade = Grenade
