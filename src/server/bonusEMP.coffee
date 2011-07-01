prefs = require './prefs'
EMP = require('./EMP').EMP

class BonusEMP
	type: 'EMP'

	constructor: (@game) ->
		@used = no

	use: () ->
		return if @used is yes

		@used = yes

		@game.newGameObject (id) =>
			@game.EMPs[id] = new EMP(@getHolder(), id)

		# Clean up.
		@getHolder().releaseBonus()
		@getBonus().setState 'dead'

	getBonus: () ->
		@game.gameObjects[@bonusId]

	getHolder: () ->
		@game.gameObjects[@getBonus().holderId]

exports.BonusEMP = BonusEMP
exports.constructor = BonusEMP
exports.type = 'bonusEMP'
