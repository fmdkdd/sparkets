server = require './server'
prefs = require './prefs'
Mine = require('./mine').Mine

class BonusMine
	type: 'mine'

	constructor: () ->
		@mines = prefs.bonus.mine.mineCount

	use: () ->
		server.game.newGameObject (id) =>
			server.game.mines[id] = new Mine(@ship, id)

		# Decrease mine count.
		--@mines

		# Clean up if there is no more mine.
		if @mines is 0
			@ship.bonus = null
			server.game.gameObjects[@bonusId].state = 'dead'

exports.BonusMine = BonusMine
exports.constructor = BonusMine
exports.type = 'bonusMine'
