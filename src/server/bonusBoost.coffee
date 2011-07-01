prefs = require './prefs'

class BonusBoost
	type: 'boost'

	constructor: (@game) ->
		@used = no
		@boostFactor = 0

	use: () ->
		return if @used

		@used = yes
		@getHolder().boost = prefs.bonus.boost.boostFactor
		@getHolder().boostDecay = 0

		# Cancel the previous pending boost decay.
		if @getHolder().bonusTimeout.bonusBoost?
			clearTimeout(@getHolder().bonusTimeout.bonusBoost)

		holderId = @getHolder().id
		@getHolder().bonusTimeout[exports.type] = setTimeout(( () =>
			@game.gameObjects[holderId].boostDecay = prefs.bonus.boost.boostDecay ),
			prefs.bonus.boost.boostDuration)

		# Clean up.
		@getHolder().releaseBonus()
		@getBonus().setState 'dead'

	getBonus: () ->
		@game.gameObjects[@bonusId]

	getHolder: () ->
		@game.gameObjects[@getBonus().holderId]

exports.BonusBoost = BonusBoost
exports.constructor = BonusBoost
exports.type = 'bonusBoost'
