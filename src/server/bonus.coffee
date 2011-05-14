ChangingObject = require('./changingObject').ChangingObject
server = require './server'
BonusMine = require('./bonusMine').BonusMine
prefs = require './prefs'
utils = require '../utils'

class Bonus extends ChangingObject
	constructor: (@id) ->
		super()

		@watchChanges 'type'
		@watchChanges 'hitRadius'
		@watchChanges 'state'
		@watchChanges 'countdown'
		@watchChanges 'color'
		@watchChanges 'modelSize'
		@watchChanges 'pos'
		@watchChanges 'serverDelete'

		@type = 'bonus'

		@hitRadius = prefs.bonus.hitRadius
		@modelSize = prefs.bonus.modelSize

		@spawn()

	spawn: () ->
		@state = 'incoming'
		@countdown = prefs.bonus.states[@state].countdown

		@pos =
			x: Math.random() * prefs.server.mapSize.w
			y: Math.random() * prefs.server.mapSize.h
		@color = utils.randomColor()
		@empty = yes
		@bonusEffet = BonusMine

		@spawn() if server.game.collidesWithPlanet(@)

	tangible: () ->
		@state isnt 'dead'

	collidesWith: ({pos: {x,y}, hitRadius}) ->
		utils.distance(@pos.x, @pos.y, x, y) < @hitRadius + hitRadius

	nextState: () ->
		@state = prefs.bonus.states[@state].next
		@countdown = prefs.bonus.states[@state].countdown

	move: () ->
		true

	update: () ->
		@countdown -= prefs.server.timestep if @countdown?

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
