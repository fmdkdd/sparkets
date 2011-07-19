class BonusStealth
	type: 'stealth'

	constructor: (@game, @bonus) ->

	use: () ->
		@bonus.holder.invisible = yes

		@bonus.holder.on 'fired', (ship, bullet) ->
			ship.invisible = no

		# Cancel all pending bonus timeouts.
		for type, timeout of @bonus.holder.bonusTimeout
			clearTimeout(timeout)

		holderId = @bonus.holder.id
		@bonus.holder.bonusTimeout[exports.type] = setTimeout(( () =>
			@game.gameObjects[holderId]?.invisible = no ),
			@game.prefs.bonus.stealth.duration)

		# Clean up.
		@bonus.holder.releaseBonus()
		@bonus.setState 'dead'

exports.BonusStealth = BonusStealth
exports.constructor = BonusStealth
exports.type = 'bonusStealth'
