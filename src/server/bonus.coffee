utils = require '../utils'
ChangingObject = require('./changingObject').ChangingObject
BonusMine = require './bonusMine'
BonusBoost = require './bonusBoost'
BonusShield = require './bonusShield'
Rope = require('./rope').Rope

class Bonus extends ChangingObject
	constructor: (@id, @game, bonusType) ->
		super()

		# Send these properties to new players.
		@flagFullUpdate('type')
		@flagFullUpdate('state')
		@flagFullUpdate('countdown')
		@flagFullUpdate('color')
		@flagFullUpdate('pos')
		@flagFullUpdate('serverDelete')
		@flagFullUpdate('bonusType')
		@flagFullUpdate('boundingRadius')
		@flagFullUpdate('hitBox') if @game.prefs.debug.sendHitBoxes

		@type = 'bonus'
		@flagNextUpdate('type')

		@boundingRadius = @game.prefs.bonus.boundingRadius

		@flagNextUpdate('boundingRadius')

		@hitBox =
			type: 'polygon'
			points: [
				{x: 0, y: 0},
				{x: 0, y: 0},
				{x: 0, y: 0},
				{x: 0, y: 0}]

		@flagNextUpdate('hitBox') if @game.prefs.debug.sendHitBoxes

		@spawn(bonusType)

	spawn: (bonusType) ->
		@pos =
			x: Math.random() * @game.prefs.mapSize
			y: Math.random() * @game.prefs.mapSize

		@updateHitbox()

		# Find a safe drop location.
		while @game.collidesWithPlanet(@)
			@pos.x = Math.random() * @game.prefs.mapSize
			@pos.y = Math.random() * @game.prefs.mapSize
			@updateHitbox()

		# Set our initial velocity.
		@vel =
			x: 0
			y: 0

		@flagNextUpdate('pos')

		# Initial state.
		@state = 'incoming'
		@countdown = @game.prefs.bonus.states[@state].countdown

		@flagNextUpdate('state')
		@flagNextUpdate('countdown')

		# Nice skittles color.
		@color = utils.randomColor()

		@flagNextUpdate('color')

		# Randomly choose bonus type if unspecified.
		if bonusType?
			bonusClass = @game.prefs.bonus.bonusType[bonusType].class
		else
			bonusClass = @randomBonus()

		# Set bonus effect and type.
		@effect = new bonusClass.constructor(@game, @)
		@bonusType = bonusClass.type

		@flagNextUpdate('bonusType')

	hitBoxPoints: [
		{x: -10, y: -10},
		{x: +10, y: -10},
		{x: +10, y: +10},
		{x: -10, y: +10}]

	updateHitbox: () ->
		for i in [0...@hitBox.points.length]
			@hitBox.points[i].x = @pos.x + @hitBoxPoints[i].x
			@hitBox.points[i].y = @pos.y + @hitBoxPoints[i].y

		@flagNextUpdate('hitBox.points') if @game.prefs.debug.sendHitBoxes

	randomBonus: () ->
		roulette = []
		for type, bonus of @game.prefs.bonus.bonusType
			i = 0
			while i < bonus.weight
				roulette.push(bonus.class)
				++i;
		return Array.random(roulette)

	tangible: () ->
		@state isnt 'incoming' and @state isnt 'dead'

	nextState: () ->
		@state = @game.prefs.bonus.states[@state].next
		@countdown = @game.prefs.bonus.states[@state].countdown

		@flagNextUpdate('state')
		@flagNextUpdate('countdown')

	setState: (state) ->
		if @game.prefs.bonus.states[state]?
			@flagNextUpdate('state') unless @state is state
			@flagNextUpdate('countdown')

			@state = state
			@countdown = @game.prefs.bonus.states[state].countdown

	move: () ->
		# Update position and hitbox according to velocity.
		unless @vel.x is 0
			@pos.x += @vel.x
			@flagNextUpdate('pos.x')

		unless @vel.y is 0
			@pos.y += @vel.y
			@flagNextUpdate('pos.y')

		# Warp around the borders.
		utils.warp(@pos, @game.prefs.mapSize)

		@updateHitbox() unless @vel.x is 0 and @vel.y is 0

		# Decay velocity.
		@vel.x *= @game.prefs.bonus.frictionDecay
		@vel.y *= @game.prefs.bonus.frictionDecay

	update: () ->
		if @countdown?
			@countdown -= @game.prefs.timestep
			# DELETEME: client should only receive the countdown once.
			@flagNextUpdate('countdown')

			@nextState() if @countdown <= 0

		switch @state
			# The bonus is of no more use.
			when 'dead'
				@serverDelete = yes
				@flagNextUpdate('serverDelete')

	use: () ->
		@effect.use()

		@game.events.push
			type: 'bonus used'
			id: @id

	attach: (ship) ->
		@holder = ship
		@setState 'claimed'

		# Attach the bonus to the ship with a rope.
		@game.newGameObject (id) =>
			@rope = new Rope(@game, id, @holder, @, 30, 4)

	release: () ->
		@holder = null
		@setState 'available'

		# We don't need the rope anymore.
		if @rope?
			@rope.detach()
			@rope = null

	explode: () ->
		@holder.releaseBonus() if @state is 'claimed'
		@setState 'dead'

		@game.events.push
			type: 'bonus exploded'
			id: @id

	isEvil: () ->
		@effect.evil?

exports.Bonus = Bonus
