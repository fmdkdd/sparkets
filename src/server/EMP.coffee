ChangingObject = require('./changingObject').ChangingObject
utils = require('../utils')

class EMP extends ChangingObject
	constructor: (@ship, @id, @game) ->
		super()

		@watchChanges 'type'
		@watchChanges 'pos'
		@watchChanges 'color'
		@watchChanges 'force'
		@watchChanges 'serverDelete'

		@type = 'EMP'

		@pos =
			x: ship.pos.x
			y: ship.pos.y

		@color = ship.color
		@force = @game.prefs.EMP.radius
		@hitRadius = @force

		@state = 'active'
		@countdown = @game.prefs.EMP.states[@state].countdown

	cancel: () ->
		@serverDelete = yes

	tangible: () ->
		yes

	collidesWith: ({pos: {x,y}, hitRadius, type}, offset = {x:0, y:0}) ->
		x += offset.x
		y += offset.y
		utils.distance(@pos.x, @pos.y, x, y) < @hitRadius + hitRadius

	move: () ->
		return if @state isnt 'active'

		# Follow ship
		@pos.x = @ship.pos.x
		@pos.y = @ship.pos.y
		@changed 'pos'

	nextState: () ->
		@state = @game.prefs.EMP.states[@state].next
		@countdown = @game.prefs.EMP.states[@state].countdown

	update: () ->
		@countdown -= @game.prefs.timestep if @countdown?

		switch @state
			when 'active'
				# Delete EMP when ship dies.
				if @ship.state isnt 'alive'
					@nextState()
					return

				# Expire EMP after a set amount of time.
				@nextState() if @countdown <= 0

			when 'dead'
				@serverDelete = yes

exports.EMP = EMP
