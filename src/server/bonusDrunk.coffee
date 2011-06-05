server = require './server'
prefs = require './prefs'

class BonusDrunk
	constructor: (@ship) ->
		@used = no
		@evil = yes

	use: () ->
		return if @used is yes

		@used = yes
		@ship.inverseTurn = yes
		@ship.bonus = null

		# Cancel all pending bonus timeouts.
		for type, timeout of @ship.bonusTimeout
			clearTimeout(timeout)

		@ship.bonusTimeout[exports.type] = setTimeout(( () =>
			@ship.inverseTurn = no ),
			prefs.bonus.drunk.duration)

exports.BonusDrunk = BonusDrunk
exports.constructor = BonusDrunk
exports.type = 'bonusDrunk'
