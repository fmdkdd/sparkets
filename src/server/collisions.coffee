exports.handle = (obj1, obj2) ->
	type1 = "#{obj1.type}-#{obj2.type}"
	type2 = "#{obj2.type}-#{obj1.type}"

	if exports.collisions[type1]?
		exports.collisions[type1](obj1, obj2)
	else if exports.collisions[type2]?
		exports.collisions[type2](obj2, obj1)

exports.collisions =
	'ship-bonus': (ship, bonus) ->
		++ship.mines if not bonus.empty
		bonus.nextState() if bonus.state is 'active'

	'ship-bullet': (ship, bullet) ->
		# Immunity to own bullets for a set time.
		if ship.id isnt bullet.owner.id or
				bullet.points.length > 10
			ship.explode()
			ship.killingAccel = bullet.accel
			bullet.state = 'dead' if bullet.state is 'active'

	'ship-mine': (ship, mine) ->
		ship.explode()
		mine.nextState() if mine.state is 'active'

	'ship-planet': (ship, planet) ->
		ship.explode()

	'ship-ship': (ship1, ship2) ->
		ship1.explode()
		ship2.explode()

	'bullet-planet': (bullet, planet) ->
		bullet.state = 'dead' if bullet.state is 'active'

	'mine-bullet': (mine, bullet) ->
		mine.nextState() if mine.state is 'active'

	'mine-mine': (mine1, mine2) ->
		# Only exploding mines trigger other mines.
		mine1.nextState() if mine2.state is 'exploding' and mine1.state is 'active'
		mine2.nextState() if mine1.state is 'exploding' and mine2.state is 'active'
