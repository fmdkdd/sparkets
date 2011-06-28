prefs = require './prefs'
EMP = require('./EMP').EMP

class BonusEMP
	type: 'EMP'

	constructor: (@ship, @game) ->
		@used = no

	use: () ->
		return if @used is yes

		@used = yes
		@game.newGameObject (id) =>
			@game.EMPs[id] = new EMP(@ship, id)
		@ship.bonus = null

exports.BonusEMP = BonusEMP
exports.constructor = BonusEMP
exports.type = 'bonusEMP'
