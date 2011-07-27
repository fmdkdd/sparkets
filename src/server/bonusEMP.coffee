utils = require('../utils')

class BonusEMP
	type: 'EMP'

	constructor: (@game, @bonus) ->

	drunkEffect: (ship) ->
		ship.inverseTurn = yes

		# Cancel the previous pending drunk decay.
		if ship.bonusTimeout.bonusDrunk?
			clearTimeout(ship.bonusTimeout.bonusDrunk)

		ship.bonusTimeout.bonusDrunk = setTimeout(( () =>
			@game.gameObjects[ship.id].inverseTurn = no ),
			@game.prefs.bonus.drunk.duration)

	use: () ->
		holder = @bonus.holder

		# Get game objects around the owner.
		cellObjsArray = @game.objectsAround holder.pos, (obj) ->
			obj isnt holder and obj.type in ['bullet', 'shield', 'mine', 'ship', 'tracker']

		r = @game.prefs.bonus.EMP.effectRadius
		for cellObjs in cellObjsArray
			for id, cellObj of cellObjs.objects
				# Only affect objects in the EMP radius.
				objX = cellObj.object.pos.x + cellObjs.relativeOffset.x
				objY = cellObj.object.pos.y + cellObjs.relativeOffset.y
				if utils.distance(objX, objY, holder.pos.x, holder.pos.y) < r
					switch cellObj.object.type
						# Explode all projectiles and mines.
						when 'bullet', 'mine', 'tracker'
							cellObj.object.explode()

						# Cancel shields.
						when 'shield'
							cellObj.object.cancel()

						# Cancel stealth and add drunk effect to ships.
						when 'ship'
							cellObj.object.invisible = no
							@drunkEffect(cellObj.object)

		@game.events.push
			type: 'EMP released'
			id: @bonus.holder.id

		@used = yes

		# Clean up.
		@bonus.holder.releaseBonus()
		@bonus.setState 'dead'

exports.BonusEMP = BonusEMP
exports.constructor = BonusEMP
exports.type = 'bonusEMP'
