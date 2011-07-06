ChangingObject = require('./changingObject').ChangingObject
BonusMine = require './bonusMine'
BonusBoost = require './bonusBoost'
utils = require '../utils'

class Bonus extends ChangingObject
	constructor: (@id, @game, bonusType) ->
		super()

		@watchChanges 'type'
		@watchChanges 'hitRadius'
		@watchChanges 'state'
		@watchChanges 'countdown'
		@watchChanges 'color'
		@watchChanges 'modelSize'
		@watchChanges 'pos'
		@watchChanges 'serverDelete'
		@watchChanges 'bonusType'

		@type = 'bonus'

		@hitRadius = @game.prefs.bonus.hitRadius
		@modelSize = @game.prefs.bonus.modelSize

		@spawn(bonusType)

	spawn: (bonusType) ->
		@state = 'incoming'
		@countdown = @game.prefs.bonus.states[@state].countdown

		@pos =
			x: Math.random() * @game.prefs.mapSize.w
			y: Math.random() * @game.prefs.mapSize.h
		@color = utils.randomColor()
		@empty = yes

		# Choose bonus type.
		if not bonusType?
			type = @randomBonus()
		else
			type = @game.prefs.bonus.bonusType[bonusType].class
		@bonusEffect = type.constructor
		@bonusType = type.type

		@spawn(bonusType) if @game.collidesWithPlanet(@)

	randomBonus: () ->
		roulette = []
		for type, bonus of @game.prefs.bonus.bonusType
			i = 0
			while i < bonus.weight
				roulette.push(bonus.class)
				++i;
		return utils.randomArrayElem roulette

	tangible: () ->
		@state isnt 'dead'

	collidesWith: ({pos: {x,y}, hitRadius}, offset = {x:0, y:0}) ->
		x += offset.x
		y += offset.y
		utils.distance(@pos.x, @pos.y, x, y) < @hitRadius + hitRadius

	nextState: () ->
		@state = @game.prefs.bonus.states[@state].next
		@countdown = @game.prefs.bonus.states[@state].countdown

	move: () ->
		true

	update: () ->
		@countdown -= @game.prefs.timestep if @countdown?

		switch @state
			# The bonus arrival is imminent!
			when 'incoming'
				@nextState() if @countdown <= 0

			# The bonus is available.
			# when 'available'

			# The bonus is of no more use.
			when 'dead'
				@serverDelete = yes

exports.Bonus = Bonus
