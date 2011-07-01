prefs = require './prefs'
Mine = require('./mine').Mine

class BonusMine
	type: 'mine'

	constructor: (@game) ->
		@used = no
		@mines = prefs.bonus.mine.mineCount

	use: () ->
		@game.newGameObject (id) =>
			dropPos =
				x: @getBonus().pos.x
				y: @getBonus().pos.y
			@game.mines[id] = new Mine(@getHolder(), dropPos, id)

		# Decrease mine count.
		--@mines

		# Clean up if there is no more mine.
		if @mines is 0
			@getHolder().releaseBonus()
			@getBonus().setState 'dead'

	getBonus: () ->
		@game.gameObjects[@bonusId]

	getHolder: () ->
		@game.gameObjects[@getBonus().holderId]

exports.BonusMine = BonusMine
exports.constructor = BonusMine
exports.type = 'bonusMine'
