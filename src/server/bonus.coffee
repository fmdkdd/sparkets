utils = require '../utils'
ChangingObject = require('./changingObject').ChangingObject
BonusMine = require './bonusMine'
BonusBoost = require './bonusBoost'
BonusEMP = require './bonusEMP'
BonusDrunk = require './bonusDrunk'
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

		@hitRadius = @game.prefs.bonus.hitRadius

		@spawn(bonusType)

	spawn: (bonusType) ->
		@state = 'incoming'
		@countdown = @game.prefs.bonus.states[@state].countdown

		@pos =
			x: Math.random() * @game.prefs.mapSize.w
			y: Math.random() * @game.prefs.mapSize.h
		@vel =
			x: 0
			y: 0

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

		@spawn(bonusType) if @game.collidesWithPlanet(@)

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

	collidesWith: ({pos: {x,y}, hitRadius}, offset = {x:0, y:0}) ->
		x += offset.x
		y += offset.y
		utils.distance(@pos.x, @pos.y, x, y) < @hitRadius + hitRadius

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

		@vel.x *= @game.prefs.ship.frictionDecay
		@vel.y *= @game.prefs.ship.frictionDecay

		@changed 'pos'

	warp: () ->
		{w, h} = @game.prefs.mapSize
		@pos.x = if @pos.x < 0 then w else @pos.x
		@pos.x = if @pos.x > w then 0 else @pos.x
		@pos.y = if @pos.y < 0 then h else @pos.y
		@pos.y = if @pos.y > h then 0 else @pos.y

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

	isEvil: () ->
		@effect.evil?

exports.Bonus = Bonus
