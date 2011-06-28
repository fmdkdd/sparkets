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
		if not bonusType?
			type = @randomBonus()
		else
			type = prefs.bonus.bonusType[bonusType].class
		@bonusEffect = type.constructor
		@bonusType = type.type

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

	move: () ->
		if @state is 'claimed'

			holder = server.game.gameObjects[@holderId]
			ghost = server.game.closestGhost(@pos.x, @pos.y, holder)
			dist = utils.distance(@pos.x, @pos.y, ghost.x, ghost.y)
			diff = dist - prefs.bonus.draggingDistance

			# Add enough velocity along the direction from the bonus to the
			# ship so that the distance constraint is enforced.
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

		console.info @pos

	update: () ->
		@countdown -= prefs.server.timestep if @countdown?

		switch @state
			# The bonus arrival is imminent!
			when 'incoming'
				@nextState() if @countdown <= 0

			# The bonus is of no more use.
			when 'dead'
				@serverDelete = yes

exports.Bonus = Bonus
