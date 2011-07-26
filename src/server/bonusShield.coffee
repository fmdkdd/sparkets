Shield = require('./shield').Shield

class BonusShield
	type: 'shield'

	constructor: (@game, @bonus) ->
		@used = no

	use: () ->
		return if @used is yes

		@game.newGameObject (id) =>
			@game.shields[id] = new Shield(@bonus.holder, id, @game)

		@used = yes

		# Clean up.
		@bonus.holder.releaseBonus()
		@bonus.setState 'dead'

exports.BonusShield = BonusShield
exports.constructor = BonusShield
exports.type = 'bonusShield'
