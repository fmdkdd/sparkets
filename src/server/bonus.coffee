ChangingObject = require './changingObject'
globals = require './server'
prefs = require './prefs'
utils = require '../utils'

class Bonus extends ChangingObject.ChangingObject
	constructor: (@id) ->
		super()

		@watchChanges 'type'
		@watchChanges 'state'
		@watchChanges 'countdown'
		@watchChanges 'color'
		@watchChanges 'modelSize'
		@watchChanges 'pos'

		@type = 'bonus'
		@modelSize = prefs.bonus.modelSize

		@spawn()

	spawn: () ->
		@state = 'incoming'
		@countdown = prefs.bonus.states[@state].countdown

		@pos =
			x: Math.random() * prefs.server.mapSize.w
			y: Math.random() * prefs.server.mapSize.h
		@color = utils.randomColor()

	nextState: () ->
		@state = prefs.bonus.states[@state].next
		@countdown = prefs.bonus.states[@state].countdown

	update: () ->
		@countdown -= prefs.server.timestep if @countdown?

		# The bonus arrival is imminent!
		switch @state
			when 'incoming'
				@nextState() if @countdown <= 0

		# The bonus is available.
			when 'active'

				# Check if a ship is touching the bonus.
				s = @modelSize
				for id, ship of globals.ships
					if not ship.isDead() and
							not ship.isExploding() and
							-s < @pos.x - ship.pos.x < s and
							-s < @pos.y - ship.pos.y < s
						++ship.mines
						@state = 'dead'
						@deleteMe = yes

exports.Bonus = Bonus
