server = require './server'
prefs = require './prefs'
Mine = require('./mine').Mine

class BonusMine
	type: 'mine'

	constructor: () ->
		@mines = prefs.bonus.mine.mineCount

	use: () ->
		server.game.newGameObject (id) =>
			dropPos =
				x: @getBonus().pos.x
				y: @getBonus().pos.y
			server.game.mines[id] = new Mine(@getHolder(), dropPos, id)

		# Decrease mine count.
		--@mines

		# Clean up if there is no more mine.
		if @mines is 0
			server.game.gameObjects[@bonusId].setState 'dead'
			server.game.gameObjects[server.game.gameObjects[@bonusId].holderId].releaseBonus()

	getBonus: () ->
		server.game.gameObjects[@bonusId]
	
	getHolder: () ->
		server.game.gameObjects[@getBonus().holderId]

exports.BonusMine = BonusMine
exports.constructor = BonusMine
exports.type = 'bonusMine'
