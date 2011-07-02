ChangingObject = require('./changingObject').ChangingObject
BonusMine = require './bonusMine'
BonusBoost = require './bonusBoost'
prefs = require './prefs'
utils = require '../utils'

class Bonus extends ChangingObject
	constructor: (@id, @game, bonusType) ->
		super()

		@watchChanges 'type'
		@watchChanges 'hitRadius'
		@watchChanges 'state'
		@watchChanges 'countdown'
		@watchChanges 'color'
		@watchChanges 'pos'
		@watchChanges 'holderId'
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
		@holderId = null
		@color = utils.randomColor()
		@empty = yes

		# Choose bonus type.
		if bonusType?
			bonusClass = prefs.bonus.bonusType[bonusType].class
		else
			bonusClass = @randomBonus()
		@bonusEffect = new bonusClass.constructor(@game)
		@bonusEffect.bonusId = @id
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
		true

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

	getHolder: () ->
		@game.gameObjects[@holderId]

	isEvil: () ->
		@bonusEffect.evil?

exports.Bonus = Bonus
