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
			ship.bonus = bonus
			bonus.bonusEffect.ship = ship
			bonus.bonusEffect.bonusId = bonus.id
			ship.useBonus() if ship.bonus.evil?
			bonus.nextState()
			bonus.holderId = ship.id

	'ship-bullet': (ship, bullet) ->
		# Immunity to own bullets for a set time.
		if bullet.state is 'available' and
				(ship.id isnt bullet.owner.id or
				bullet.points.length > 3)
			ship.explode()
			ship.killingAccel = bullet.accel
			bullet.state = 'dead'

	'ship-mine': (ship, mine) ->
		ship.explode()
		mine.nextState() if mine.state is 'active'

	'ship-moon': (ship, moon) ->
		ship.explode()

	'ship-planet': (ship, planet) ->
		ship.explode()

	'ship-ship': (ship1, ship2) ->
		# Boost bonus grants immunity except when both have it.
		boost1 = ship1.boost > 1
		boost2 = ship2.boost > 1

		# Ship1 has boost, not ship2.
		if boost1 and not boost2
			ship2.explode()
			ship2.killingAccel = ship1.vel
		# Ship2 has boost, not ship1.
		else if boost2 and not boost1
			ship1.explode()
			ship1.killingAccel = ship2.vel
		# Both or none have boost.
		else
			ship1.explode()
			ship1.killingAccel = ship2.vel
			ship2.explode()
			ship2.killingAccel = ship1.vel

	'bullet-moon': (bullet, moon) ->
		bullet.state = 'dead' if bullet.state is 'active'

	'bullet-planet': (bullet, planet) ->
		bullet.state = 'dead' if bullet.state is 'active'

	'mine-bullet': (mine, bullet) ->
		mine.nextState() if mine.state is 'active'

	'mine-mine': (mine1, mine2) ->
		# Only exploding mines trigger other mines.
		mine1.nextState() if mine2.state is 'exploding' and mine1.state is 'active'
		mine2.nextState() if mine1.state is 'exploding' and mine2.state is 'active'
