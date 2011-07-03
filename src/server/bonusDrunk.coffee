prefs = require './prefs'

class BonusDrunk
	type: 'drunk'

	constructor: (@game, @bonus) ->
		@used = no
		@evil = yes

	use: () ->
		return if @used is yes

		@used = yes
		@bonus.holder.inverseTurn = yes

		# Cancel all pending bonus timeouts.
		for type, timeout of @bonus.holder.bonusTimeout
			clearTimeout(timeout)

		holderId = @bonus.holder.id
		@bonus.holder.bonusTimeout[exports.type] = setTimeout(( () =>
			@game.gameObjects[holderId].inverseTurn = no ),
			prefs.bonus.drunk.duration)

		# Clean up.
		@bonus.holder.releaseBonus()
		@bonus.setState 'dead'

exports.BonusDrunk = BonusDrunk
exports.constructor = BonusDrunk
exports.type = 'bonusDrunk'
