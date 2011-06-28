server = require './server'
prefs = require './prefs'
EMP = require('./EMP').EMP

class BonusEMP
	type: 'EMP'

	constructor: () ->
		@used = no

	use: () ->
		return if @used is yes

		@used = yes
		server.game.newGameObject (id) =>
			server.game.EMPs[id] = new EMP(@ship, id)

		# Clean up.
		@ship.bonus = null
		server.game.gameObjects[@bonusId].state = 'dead'

exports.BonusEMP = BonusEMP
exports.constructor = BonusEMP
exports.type = 'bonusEMP'
