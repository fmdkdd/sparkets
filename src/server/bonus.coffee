utils = require '../utils'
ChangingObject = require('./changingObject').ChangingObject
BonusMine = require './bonusMine'
BonusBoost = require './bonusBoost'
BonusShield = require './bonusShield'
BonusDrunk = require './bonusDrunk'
Rope = require('./rope').Rope

class Bonus extends ChangingObject
	constructor: (@id, @game, bonusType) ->
		super()

		@watchChanges 'type'
		@watchChanges 'state'
		@watchChanges 'countdown'
		@watchChanges 'color'
		@watchChanges 'pos'
		@watchChanges 'serverDelete'
		@watchChanges 'bonusType'
		@watchChanges 'hitBox' if @game.prefs.debug.sendHitBoxes
		@watchChanges 'boundingRadius'

		@type = 'bonus'

		@boundingRadius = @game.prefs.bonus.boundingRadius
		r = @boundingRadius/2
		@hitBox =
			type: 'polygon'
			points: [
				{x: 0, y: 0},
				{x: 0, y: 0},
				{x: 0, y: 0},
				{x: 0, y: 0}]

		@spawn(bonusType)

	spawn: (bonusType) ->
		@state = 'incoming'
		@countdown = @game.prefs.bonus.states[@state].countdown

		@color = utils.randomColor()
		@empty = yes

		@holder = null
		@rope = null

		# Choose bonus type.
		if bonusType?
			bonusClass = @game.prefs.bonus.bonusType[bonusType].class
		else
			bonusClass = @randomBonus()
		@effect = new bonusClass.constructor(@game, @)
		@bonusType = bonusClass.type

		@pos =
			x: Math.random() * @game.prefs.mapSize
			y: Math.random() * @game.prefs.mapSize
		@vel =
			x: 0
			y: 0

		@updateHitbox()

		@spawn(bonusType) if @game.collidesWithPlanet(@)

	hitBoxPoints: [
		{x: -10, y: -10},
		{x: +10, y: -10},
		{x: +10, y: +10},
		{x: -10, y: +10}]

	updateHitbox: () ->
		for i in [0...@hitBox.points.length]
			@hitBox.points[i].x = @pos.x + @hitBoxPoints[i].x
			@hitBox.points[i].y = @pos.y + @hitBoxPoints[i].y

		@changed 'hitBox'

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

	setState: (state) ->
		if @game.prefs.bonus.states[state]?
			@state = state
			@countdown = @game.prefs.bonus.states[state].countdown

	move: () ->
		@pos.x += @vel.x
		@pos.y += @vel.y
		@warp()

		if @vel.x isnt 0 or @vel.y isnt 0
			@changed 'pos'
			@updateHitbox()
			console.info @vel.x

		@vel.x *= @game.prefs.ship.frictionDecay
		@vel.y *= @game.prefs.ship.frictionDecay

	warp: () ->
		s = @game.prefs.mapSize
		@pos.x = if @pos.x < 0 then s else @pos.x
		@pos.x = if @pos.x > s then 0 else @pos.x
		@pos.y = if @pos.y < 0 then s else @pos.y
		@pos.y = if @pos.y > s then 0 else @pos.y

	update: () ->
		if @countdown?
			@countdown -= @game.prefs.timestep
			@nextState() if @countdown <= 0

		switch @state

			# The bonus is of no more use.
			when 'dead'
				@serverDelete = yes

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
