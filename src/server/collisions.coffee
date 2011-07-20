logger = require('../logger').static

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
			ddebug "ship ##{ship.id} picked up #{bonus.bonusType} bonus ##{bonus.id}"
			ship.holdBonus(bonus)
			ship.useBonus() if bonus.isEvil()

			ddebug "ship ##{ship.id} claimed bonus ##{bonus.id}"

	'ship-bullet': (ship, bullet) ->
		# Immunity to own bullets for a set time.
		if ship.state is 'alive' and
				bullet.state is 'active' and
				(ship.id isnt bullet.owner.id or
				bullet.points.length > 3)
			ship.explode()
			ship.killingAccel = bullet.accel
			bullet.owner.addStat('kills', 1) if bullet.owner isnt ship
			bullet.explode()

			ddebug "bullet ##{bullet.id} killed ship ##{ship.id}"

	'ship-mine': (ship, mine) ->
		ship.explode()
		mine.explode() if mine.state is 'active'
		mine.owner.addStat('kills', 1) if mine.owner isnt ship

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
		bullet.explode() if bullet.state is 'active'

		ddebug "bullet ##{bullet.id} hit moon ##{moon.id}"

	'bullet-planet': (bullet, planet) ->
		bullet.explode() if bullet.state is 'active'

		ddebug "bullet ##{bullet.id} hit planet ##{planet.id}"

	'EMP-bullet': (EMP, bullet) ->
		# EMPs absorb all bullets, except from the user!
		bullet.explode() if bullet.state is 'active' and bullet.owner isnt EMP.ship

		ddebug "EMP ##{EMP.id} hit bullet ##{bullet.id}"

	'EMP-EMP': (EMP1, EMP2) ->
		# EMPs cancel each other.
		EMP1.cancel()
		EMP2.cancel()

		ddebug "EMP ##{EMP1.id} hit EMP ##{EMP2.id}"

	'EMP-mine': (EMP, mine) ->
		# EMPs absorb one mine.
		mine.explode() if mine.state is 'active'
		EMP.cancel()
		ddebug "EMP ##{EMP.id} hit mine ##{mine.id}"

	# EMPs do not save ships from moons or planets ...

	'EMP-ship': (EMP, ship) ->
		# EMPs can't take more than one ship.
		if EMP.ship isnt ship
			ship.explode()
			EMP.cancel()

		ddebug "EMP ##{EMP.id} hit ship ##{ship.id}"

	'EMP-tracker': (EMP, tracker) ->
		# EMPs absorb one tracker.
		tracker.explode()
		EMP.cancel()

		ddebug "EMP ##{EMP.id} hit tracker ##{tracker.id}"

	'mine-bullet': (mine, bullet) ->
		mine.explode() if mine.state is 'active'

		ddebug "bullet ##{bullet.id} hit mine ##{mine.id}"

	'mine-moon': (mine, moon) ->
		mine.explode() if mine.state is 'active'

		ddebug "bullet ##{mine.id} hit moon ##{moon.id}"

	'mine-mine': (mine1, mine2) ->
		# Only exploding mines trigger other mines.
		if mine2.state is 'exploding' and mine1.state is 'active'
			mine1.explode()
			ddebug "mine ##{mine2.id} triggered mine ##{mine1.id}"

		if mine1.state is 'exploding' and mine2.state is 'active'
			mine2.explode()
			ddebug "mine ##{mine1.id} triggered mine ##{mine2.id}"

	'bullet-bonus': (bullet, bonus) ->
		bonus.explode()

		ddebug "bullet ##{bullet.id} destroyed bonus ##{bonus.id}"

	'bonus-planet': (bonus, planet) ->
		bonus.explode()

		ddebug "bonus ##{bonus.id} crashed on planet ##{planet.id}"

	'bonus-moon': (bonus, moon) ->
		bonus.explode()

		ddebug "bonus ##{bonus.id} crashed on moon ##{moon.id}"

	'tracker-planet' : (tracker, planet) ->
		tracker.explode()

		ddebug "tracker ##{tracker.id} crashed on planet ##{planet.id}"

	'tracker-moon' : (tracker, moon) ->
		tracker.explode()

		ddebug "tracker ##{tracker.id} crashed on moon ##{moon.id}"

	'tracker-ship' : (tracker, ship) ->
		tracker.explode()
		ship.explode()
		tracker.owner.addStat('kills', 1) if tracker.owner isnt ship

		ddebug "tracker ##{tracker.id} destroyed ship ##{ship.id}"

	'tracker-bullet' : (tracker, bullet) ->
		tracker.explode()
		bullet.explode()

		ddebug "bullet ##{bullet.id} destroyed tracker ##{tracker.id}"

	'tracker-mine' : (tracker, mine) ->
		tracker.explode()
		mine.explode()

		ddebug "mine ##{mine.id} destroyed tracker ##{tracker.id}"
