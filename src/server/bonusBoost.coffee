class BonusBoost
	type: 'boost'

	constructor: (@ship, @game) ->
		@boostFactor = 0
		@used = no

	use: () ->
		return if @used is yes

		@used = yes
		@ship.boost = @game.prefs.bonus.boost.boostFactor
		@ship.boostDecay = 0
		@ship.bonus = null

		# Cancel the previous pending boost decay.
		if @ship.bonusTimeout['bonusBoost']?
			clearTimeout(@ship.bonusTimeout['bonusBoost'])

		@ship.bonusTimeout[exports.type] = setTimeout(( () =>
			@ship.boostDecay = @game.prefs.bonus.boost.boostDecay ),
			@game.prefs.bonus.boost.boostDuration)

exports.BonusBoost = BonusBoost
exports.constructor = BonusBoost
exports.type = 'bonusBoost'
