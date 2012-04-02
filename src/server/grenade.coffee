ChangingObject = require('./changingObject').ChangingObject
stateMachineMixin = require('./stateMachine').mixin
utils = require '../utils'

class Grenade extends ChangingObject

	stateMachineMixin.call(@prototype)

	constructor: (@id, @game, @owner, @pos, @vel, @willFragment) ->
		super()

		# Send these properties to new players.
		@flagFullUpdate('type')
		@flagFullUpdate('ownerId')
		@flagFullUpdate('pos')
		@flagFullUpdate('radius')
		@flagFullUpdate('state')
		@flagFullUpdate('serverDelete')
		if @game.prefs.debug.sendHitBoxes
			@flagFullUpdate('boundingBox')
			@flagFullUpdate('hitBox')

		@type = 'grenade'
		@flagNextUpdate('type')

		# Transmit owner's id to colients.
		@ownerId = @owner.id
		@flagNextUpdate('ownerId')

		# Initial state.
		@setState 'active'

		@pos =
			x: pos.x
			y: pos.y
		@flagNextUpdate('pos')

		@initialVel =
			x: @vel.x
			y: @vel.y

		@radius = @game.prefs.grenade.radius
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
		@state is 'active' or @state is 'fragmenting' or @state is 'exploding'

	move: (step) ->

		if @vel.x isnt 0 and @vel.y isnt 0

			@pos.x += @vel.x
			@pos.y += @vel.y
			@flagNextUpdate('pos')

			@boundingBox.x = @hitBox.x = @pos.x
			@boundingBox.y = @hitBox.y = @pos.y
			if @game.prefs.debug.sendHitBoxes
				@flagNextUpdate('boundingBox')
				@flagNextUpdate('hitBox')

		@vel = utils.vec.times(@vel, @game.prefs.grenade.friction)

	update: (step) ->

		oldState = @state

		@updateState(step)

		if @state isnt oldState
			switch @state
				when 'exploding'
					@explode()
					@fragment() if @willFragment
				when 'dead'
					@serverDelete = yes
					@flagNextUpdate('serverDelete')

	fragment: () ->

		return if not @willFragment

		childrenCount = @game.prefs.grenade.childrenCount
		splitAngle = 2 * Math.PI / childrenCount

		for i in [0...childrenCount]

			@game.newGameObject (id) =>

				pos =
					x: @pos.x
					y: @pos.y

				vel =
					x: Math.cos(i * splitAngle + splitAngle / 2)
					y: Math.sin(i * splitAngle + splitAngle / 2)
				vel = utils.vec.times(utils.vec.unit(vel), @game.prefs.grenade.velocity)

				@game.grenades[id] = new Grenade(id, @game, @owner, pos, vel, no)

	explode: () ->

		@setState 'exploding'

		# Increase radius.
		@radius = @game.prefs.grenade.explosionRadius
		@flagNextUpdate('radius')

		# Update hit box radius.
		@boundingBox.radius = @hitBox.radius = @radius
		if @game.prefs.debug.sendHitBoxes
			@flagNextUpdate('boundingBox.radius')
			@flagNextUpdate('hitBox.radius')

		@game.events.push
			type: 'grenade exploded'
			id: @id

exports.Grenade = Grenade
