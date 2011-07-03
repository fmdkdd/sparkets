prefs = require './prefs'

class BonusBoost
	type: 'boost'

	constructor: (@game, @bonus) ->
		@used = no
		@boostFactor = 0

	use: () ->
		return if @used

		@used = yes
		@bonus.holder.boost = prefs.bonus.boost.boostFactor
		@bonus.holder.boostDecay = 0

		# Cancel the previous pending boost decay.
		if @bonus.holder.bonusTimeout.bonusBoost?
			clearTimeout(@bonus.holder.bonusTimeout.bonusBoost)

		holderId = @bonus.holder.id
		@bonus.holder.bonusTimeout[exports.type] = setTimeout(( () =>
			@game.gameObjects[holderId].boostDecay = prefs.bonus.boost.boostDecay ),
			prefs.bonus.boost.boostDuration)

		# Clean up.
		@bonus.holder.releaseBonus()
		@bonus.setState 'dead'

exports.BonusBoost = BonusBoost
exports.constructor = BonusBoost
exports.type = 'bonusBoost'
