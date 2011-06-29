server = require './server'
prefs = require './prefs'

class BonusDrunk
	type: 'drunk'

	constructor: () ->
		@used = no
		@evil = yes

	use: () ->
		return if @used is yes

		@used = yes
		@getHolder().inverseTurn = yes

		# Cancel all pending bonus timeouts.
		for type, timeout of @getHolder().bonusTimeout
			clearTimeout(timeout)

		holderId = @getHolder().id
		@getHolder().bonusTimeout[exports.type] = setTimeout(( () =>
			server.game.gameObjects[holderId].inverseTurn = no ),
			prefs.bonus.drunk.duration)

		#Clean up.
		@getHolder().releaseBonus()
		@getBonus().setState 'dead'

	getBonus: () ->
		server.game.gameObjects[@bonusId]
	
	getHolder: () ->
		server.game.gameObjects[@getBonus().holderId]

exports.BonusDrunk = BonusDrunk
exports.constructor = BonusDrunk
exports.type = 'bonusDrunk'
