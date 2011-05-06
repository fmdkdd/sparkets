ChangingObject = require './changingObject'
globals = require './server'
prefs = require './prefs'
utils = require '../utils'

class Bonus extends ChangingObject.ChangingObject
	constructor: (@id) ->
		super()

		@watchChanges 'type'
		@watchChanges 'state'
		@watchChanges 'color'
		@watchChanges 'modelSize'
		@changed 'pos'

		@type = 'bonus'
		@state = 'incoming'
		@pos =
			x: Math.random()*prefs.server.mapSize.w
			y: Math.random()*prefs.server.mapSize.h
		@color = utils.randomColor()
		@modelSize = prefs.bonus.modelSize

	update: () ->
		s = @modelSize

		# Check if a ship is touching the bonus.
		if @state isnt 'dead'
			for id, ship of globals.ships
				if not ship.isDead() and
						not ship.isExploding() and
						-s < @pos.x - ship.pos.x < s and
						-s < @pos.y - ship.pos.y < s
					++ship.mines
					@state = 'dead'

exports.Bonus = Bonus
