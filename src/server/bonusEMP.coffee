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
			server.game.EMPs[id] = new EMP(@getHolder(), id)

		# Clean up.
		@getHolder().bonus = null
		@getBonus().state = 'dead'

	getBonus: () ->
		server.game.gameObjects[@bonusId]
	
	getHolder: () ->
		server.game.gameObjects[@getBonus().holderId]


exports.BonusEMP = BonusEMP
exports.constructor = BonusEMP
exports.type = 'bonusEMP'
