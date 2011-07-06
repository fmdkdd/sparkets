ChangingObject = require('./changingObject').ChangingObject

class EMP extends ChangingObject
	constructor: (ship, @id, @game) ->
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
		@force = @game.prefs.bonus.emp.initialForce

	tangible: () ->
		no

	move: () ->

	update: () ->
		@force += @game.prefs.bonus.emp.forceIncrease

		@serverDelete = yes if @force >= @game.prefs.bonus.emp.maxForce

exports.EMP = EMP