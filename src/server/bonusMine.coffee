server = require './server'
prefs = require './prefs'
Mine = require('./mine').Mine

class BonusMine
	constructor: (@ship) ->
		@mines = prefs.bonus.mine.mineCount

	use: () ->
		return if @mines == 0

		server.game.newGameObject (id) =>
			server.game.mines[id] = new Mine(@ship, id)

		--@mines

exports.BonusMine = BonusMine