Mine = require('./mine').Mine

class BonusMine
	type: 'mine'

	constructor: (@ship, @game) ->
		@mines = @game.prefs.bonus.mine.mineCount

	use: () ->
		return if @mines == 0

		@game.newGameObject (id) =>
			@game.mines[id] = new Mine(@ship, id, @game)

		--@mines
		@ship.bonus = null if @mines == 0

exports.BonusMine = BonusMine
exports.constructor = BonusMine
exports.type = 'bonusMine'
