prefs = require './prefs'
Mine = require('./mine').Mine

class BonusMine
	type: 'mine'

	constructor: (@game, @bonus) ->
		@used = no
		@mines = prefs.bonus.mine.mineCount

	use: () ->
		@game.newGameObject (id) =>
			dropPos =
				x: @bonus.pos.x
				y: @bonus.pos.y
			@game.mines[id] = new Mine(@bonus.holder, dropPos, id)

		# Decrease mine count.
		--@mines

		# Clean up if there is no more mine.
		if @mines is 0
			@bonus.holder.releaseBonus()
			@bonus.setState 'dead'

exports.BonusMine = BonusMine
exports.constructor = BonusMine
exports.type = 'bonusMine'
