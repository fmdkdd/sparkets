ChangingObject = require('./changingObject').ChangingObject
prefs = require './prefs'

class EMP extends ChangingObject
	constructor: (ship, @id) ->
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
		@force = prefs.bonus.emp.initialForce

	tangible: () ->
		no

	move: () ->

	update: () ->
		@force += prefs.bonus.emp.forceIncrease

		@serverDelete = yes if @force >= prefs.bonus.emp.maxForce

exports.EMP = EMP