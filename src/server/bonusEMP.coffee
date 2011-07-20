EMP = require('./EMP').EMP

class BonusEMP
	type: 'EMP'

	constructor: (@game, @bonus) ->
		@used = no

	use: () ->
		return if @used is yes

		@game.newGameObject (id) =>
			@game.EMPs[id] = new EMP(@bonus.holder, id, @game)

		@used = yes

		# Clean up.
		@bonus.holder.releaseBonus()
		@bonus.setState 'dead'

exports.BonusEMP = BonusEMP
exports.constructor = BonusEMP
exports.type = 'bonusEMP'
