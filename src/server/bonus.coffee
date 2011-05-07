ChangingObject = require './changingObject'
prefs = require './prefs'
utils = require '../utils'

class Bonus extends ChangingObject.ChangingObject
	constructor: (@id) ->
		super()

		@watchChanges 'type'
		@watchChanges 'hitRadius'
		@watchChanges 'state'
		@watchChanges 'countdown'
		@watchChanges 'color'
		@watchChanges 'modelSize'
		@watchChanges 'pos'

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
		@collisions = []

	collidesWith: ({pos: {x,y}, hitRadius}) ->
		@state isnt 'dead' and utils.distance(@pos.x, @pos.y, x, y) < @hitRadius + hitRadius

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
			when 'active'
				@nextState() if @collidedWith 'ship'

			# The bonus is of no more use.
			when 'dead'
				@deleteMe = yes

exports.Bonus = Bonus
