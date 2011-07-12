class BonusBoost
	type: 'boost'

	constructor: (@game, @bonus) ->

	use: () ->
		@bonus.holder.boost = @game.prefs.bonus.boost.boostFactor
		@bonus.holder.boostDecay = 0

		@used = yes

		# Cancel the previous pending boost decay.
		if @bonus.holder.bonusTimeout.bonusBoost?
			clearTimeout(@bonus.holder.bonusTimeout.bonusBoost)

		holderId = @bonus.holder.id
		@bonus.holder.bonusTimeout[exports.type] = setTimeout(( () =>
			@game.gameObjects[holderId].boostDecay = @game.prefs.bonus.boost.boostDecay ),
			@game.prefs.bonus.boost.boostDuration)

		# Clean up.
		@bonus.holder.releaseBonus()
		@bonus.setState 'dead'

exports.BonusBoost = BonusBoost
exports.constructor = BonusBoost
exports.type = 'bonusBoost'
