server = require './server'
prefs = require './prefs'

class BonusBoost
	type: 'boost'

	constructor: () ->
		@boostFactor = 0
		@used = no

	use: () ->
		return if @used

		@used = yes
		@getHolder().boost = prefs.bonus.boost.boostFactor
		@getHolder().boostDecay = 0

		# Cancel the previous pending boost decay.
		if @getHolder().bonusTimeout.bonusBoost?
			clearTimeout(@getHolder().bonusTimeout.bonusBoost)

		@getHolder().bonusTimeout[exports.type] = setTimeout(( () =>
			@getHolder().boostDecay = prefs.bonus.boost.boostDecay ),
			prefs.bonus.boost.boostDuration)

		# Clean up.
		@getHolder.releaseBonus()
		@getBonus().state = 'dead'

	getBonus: () ->
		server.game.gameObjects[@bonusId]
	
	getHolder: () ->
		server.game.gameObjects[@getBonus().holderId]

exports.BonusBoost = BonusBoost
exports.constructor = BonusBoost
exports.type = 'bonusBoost'
