prefs = require './prefs'
utils = require '../utils'
BonusMine = require './bonusMine'
BonusBoost = require './bonusBoost'
ChangingObject = require('./changingObject').ChangingObject
Rope = require('./rope').Rope

class Bonus extends ChangingObject
	constructor: (@id, @game, bonusType) ->
		super()

		@watchChanges 'type'
		@watchChanges 'hitRadius'
		@watchChanges 'state'
		@watchChanges 'countdown'
		@watchChanges 'color'
		@watchChanges 'pos'
		@watchChanges 'vel'
		@watchChanges 'serverDelete'
		@watchChanges 'bonusType'

		@type = 'bonus'

		@hitRadius = prefs.bonus.hitRadius

		@spawn(bonusType)

	spawn: (bonusType) ->
		@state = 'incoming'
		@countdown = prefs.bonus.states[@state].countdown

		@pos =
			x: Math.random() * prefs.server.mapSize.w
			y: Math.random() * prefs.server.mapSize.h
		@vel =
			x: 0
			y: 0
		@color = utils.randomColor()
		@empty = yes

		@holder = null
		@rope = null

		# Choose bonus type.
		if bonusType?
			bonusClass = prefs.bonus.bonusType[bonusType].class
		else
			bonusClass = @randomBonus()
		@bonusEffect = new bonusClass.constructor(@game, @)
		@bonusType = bonusClass.type

		@spawn(bonusType) if @game.collidesWithPlanet(@)

	randomBonus: () ->
		roulette = []
		for type, bonus of prefs.bonus.bonusType
			i = 0
			while i < bonus.weight
				roulette.push(bonus.class)
				++i;
		return utils.randomArrayElem roulette

	tangible: () ->
		@state isnt 'incoming' and @state isnt 'dead'

	collidesWith: ({pos: {x,y}, hitRadius}, offset = {x:0, y:0}) ->
		x += offset.x
		y += offset.y
		utils.distance(@pos.x, @pos.y, x, y) < @hitRadius + hitRadius

	nextState: () ->
		@state = prefs.bonus.states[@state].next
		@countdown = prefs.bonus.states[@state].countdown

	setState: (state) ->
		if prefs.bonus.states[state]?
			@state = state
			@countdown = prefs.bonus.states[state].countdown

	move: () ->
		@pos.x += @vel.x
		@pos.y += @vel.y
		@warp()

		@vel.x *= prefs.ship.frictionDecay
		@vel.y *= prefs.ship.frictionDecay

		@changed 'pos'

	warp: () ->
		{w, h} = prefs.server.mapSize
		@pos.x = if @pos.x < 0 then w else @pos.x
		@pos.x = if @pos.x > w then 0 else @pos.x
		@pos.y = if @pos.y < 0 then h else @pos.y
		@pos.y = if @pos.y > h then 0 else @pos.y

	update: () ->
		@countdown -= prefs.server.timestep if @countdown?

		switch @state
			# The bonus arrival is imminent.
			when 'incoming'
				@nextState() if @countdown <= 0

			# The bonus is exploding.
			when 'exploding'
				@nextState() if @countdown <= 0

			# The bonus is of no more use.
			when 'dead'
				@serverDelete = yes

	use: () ->
		@bonusEffect.use()

	attach: (ship) ->
		@holder = ship
		@setState 'claimed'

		# Attach the bonus to the ship with a rope.
		@game.newGameObject (id) =>
			@rope = new Rope(@game, id, @holder, @, 60, 4)

	release: () ->
		@holder = null
		@setState 'available'

		# We don't need the rope anymore.
		if @rope?
			@rope.detach()
			@rope = null				

	isEvil: () ->
		@bonusEffect.evil?

exports.Bonus = Bonus
