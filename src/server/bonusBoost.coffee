server = require './server'
prefs = require './prefs'

class BonusBoost
	constructor: (@ship) ->
		@boostFactor = 0
		@used = no

	use: () ->
		return if @used is yes

		@used = yes
		@ship.boost = prefs.bonus.boost.boostFactor
		@ship.boostDecay = 0
		@ship.bonus = null

		# Cancel the previous pending boost decay.
		clearTimeout(@ship.bonusTimeout) if @ship.bonusTimeout?

		setTimeout(( () =>
			@ship.boostDecay = prefs.bonus.boost.boostDecay ),
			prefs.bonus.boost.boostDuration)

exports.BonusBoost = BonusBoost
exports.constructor = BonusBoost
exports.type = 'bonusBoost'
