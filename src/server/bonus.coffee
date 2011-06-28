ChangingObject = require('./changingObject').ChangingObject
server = require './server'
BonusMine = require './bonusMine'
BonusBoost = require './bonusBoost'
prefs = require './prefs'
utils = require '../utils'

class Bonus extends ChangingObject
	constructor: (@id, bonusType) ->
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
		@bonusEffect = new bonusClass.constructor()
		@bonusEffect.bonusId = @id
		@bonusType = bonusClass.type

		@spawn(bonusType) if server.game.collidesWithPlanet(@)

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
		if prefs.mine.states[state]?
			@state = state
			@countdown = prefs.mine.states[state].countdown

	move: () ->
		console.log @state
		return if @state isnt 'claimed'

		holder = server.game.gameObjects[@holderId]
		ghost = server.game.closestGhost(@pos.x, @pos.y, holder)
		dist = utils.distance(@pos.x, @pos.y, ghost.x, ghost.y)
		diff = dist - prefs.bonus.draggingDistance

		# Enforce the distance constraint between the bonus and the
		# dragging ship.
		if diff > 0
			ratio = diff / dist
			@pos.x += ratio * (ghost.x - @pos.x)
			@pos.y += ratio * (ghost.y - @pos.y)

			# Warp the bonus around the map.
			{w, h} = prefs.server.mapSize
			@pos.x = if @pos.x < 0 then w else @pos.x
			@pos.x = if @pos.x > w then 0 else @pos.x
			@pos.y = if @pos.y < 0 then h else @pos.y
			@pos.y = if @pos.y > h then 0 else @pos.y

			@changed 'pos'

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
		server.game.gameObjects[@holderId]

exports.Bonus = Bonus
