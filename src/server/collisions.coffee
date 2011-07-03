logger = require './logger'

ddebug = (msg) -> logger.log 'collisions', msg

exports.handle = (obj1, obj2) ->
	type1 = "#{obj1.type}-#{obj2.type}"
	type2 = "#{obj2.type}-#{obj1.type}"

	if exports.collisions[type1]?
		exports.collisions[type1](obj1, obj2)
	else if exports.collisions[type2]?
		exports.collisions[type2](obj2, obj1)

exports.collisions =
	'ship-bonus': (ship, bonus) ->
		if bonus.state is 'available'
			ship.holdBonus(bonus)
			ddebug "ship ##{ship.id} picked up #{bonus.bonusType} bonus ##{bonus.id}"
			ship.useBonus() if bonus.isEvil()

	'ship-bullet': (ship, bullet) ->
		# Immunity to own bullets for a set time.
		if bullet.state is 'available' and
				(ship.id isnt bullet.owner.id or
				bullet.points.length > 3)
			ship.explode()
			ship.killingAccel = bullet.accel
			bullet.state = 'dead'

			ddebug "bullet ##{bullet.id} killed ship ##{ship.id}"

	'ship-mine': (ship, mine) ->
		ship.explode()
		mine.nextState() if mine.state is 'active'

		ddebug "mine ##{mine.id} killed ship ##{ship.id}"

	'ship-moon': (ship, moon) ->
		ship.explode()

		ddebug "ship ##{ship.id} crashed on moon ##{moon.id}"

	'ship-planet': (ship, planet) ->
		ship.explode()

		ddebug "ship ##{ship.id} crashed on planet ##{planet.id}"

	'ship-ship': (ship1, ship2) ->
		# Boost bonus grants immunity except when both have it.
		boost1 = ship1.boost > 1
		boost2 = ship2.boost > 1

		# Ship1 has boost, not ship2.
		if boost1 and not boost2
			ship2.explode()
			ship2.killingAccel = ship1.vel

			ddebug "ship ##{ship1.id} boosted through ship ##{ship2.id}"

		# Ship2 has boost, not ship1.
		else if boost2 and not boost1
			ship1.explode()
			ship1.killingAccel = ship2.vel

			ddebug "ship ##{ship2.id} boosted through ship ##{ship1.id}"

		# Both or none have boost.
		else
			ship1.explode()
			ship1.killingAccel = ship2.vel
			ship2.explode()
			ship2.killingAccel = ship1.vel

			ddebug "ship ##{ship1.id} and ship ##{ship2.id} crashed"

	'bullet-moon': (bullet, moon) ->
		bullet.state = 'dead' if bullet.state is 'active'

		ddebug "bullet ##{bullet.id} hit moon ##{moon.id}"

	'bullet-planet': (bullet, planet) ->
		bullet.state = 'dead' if bullet.state is 'active'

		ddebug "bullet ##{bullet.id} hit planet ##{planet.id}"

	'mine-bullet': (mine, bullet) ->
		mine.nextState() if mine.state is 'active'

		ddebug "bullet ##{bullet.id} hit mine ##{mine.id}"

	'mine-mine': (mine1, mine2) ->
		# Only exploding mines trigger other mines.
		if mine2.state is 'exploding' and mine1.state is 'active'
			mine1.nextState()
			ddebug "mine ##{mine2.id} triggered mine ##{mine1.id}"

		if mine1.state is 'exploding' and mine2.state is 'active'
			mine2.nextState()
			ddebug "mine ##{mine1.id} triggered mine ##{mine2.id}"

	'bullet-bonus': (bullet, bonus) ->
		if bonus.state is 'claimed'
			bonus.getHolder().releaseBonus()
			bonus.setState 'exploding'
		if bonus.state is 'available'
			bonus.setState 'exploding'
