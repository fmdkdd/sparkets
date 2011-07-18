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
		@force = @game.prefs.bonus.emp.initialForce
		@hitRadius = @force

	cancel: () ->
		@serverDelete = yes

	tangible: () ->
		yes

	collidesWith: ({pos: {x,y}, hitRadius, type}, offset = {x:0, y:0}) ->
		x += offset.x
		y += offset.y
		utils.distance(@pos.x, @pos.y, x, y) < @hitRadius + hitRadius

	move: () ->
		# Follow ship
		@pos.x = @ship.pos.x
		@pos.y = @ship.pos.y
		@changed 'pos'

	update: () ->
		# Delete EMP when ship dies.
		@cancel() if @ship.state isnt 'alive'

exports.EMP = EMP
