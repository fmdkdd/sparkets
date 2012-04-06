EMP = require('./EMP').EMP
utils = require('../utils')

class BonusEMP
	type: 'EMP'

	constructor: (@game, @bonus) ->

	use: () ->
		@game.newGameObject (id) =>
			@game.EMPs[id] = new EMP(id, @game, @bonus.holder)

		@bonus.holder.releaseBonus()
		@bonus.setState 'dead'

exports.BonusEMP = BonusEMP
exports.constructor = BonusEMP
exports.type = 'bonusEMP'
