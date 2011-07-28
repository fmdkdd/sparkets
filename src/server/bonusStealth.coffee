class BonusStealth
	type: 'stealth'

	constructor: (@game, @bonus) ->

	use: () ->
		ship = @bonus.holder

		ship.invisible = yes
		ship.flagNextUpdate('invisible')

		# Cancel the previous pending stealth cancel.
		if ship.bonusTimeout.bonusStealth?
			clearTimeout(ship.bonusTimeout.bonusStealth)

		ship.bonusTimeout.bonusStealth = setTimeout(( () =>
			if @game.gameObjects[ship.id]?.invisible
				@game.gameObjects[ship.id]?.flagNextUpdate('invisible')
			@game.gameObjects[ship.id]?.invisible = no ),
			@game.prefs.bonus.stealth.duration)

		# Clean up.
		ship.releaseBonus()
		@bonus.setState 'dead'

exports.BonusStealth = BonusStealth
exports.constructor = BonusStealth
exports.type = 'bonusStealth'
