utils = require '../utils'
logger = require('../logger').static

ddebug = (msg) -> logger.log 'collisions', msg

exports.test = (obj1, obj2) ->
	type1 = "#{obj1.hitBox.type}-#{obj2.hitBox.type}"
	type2 = "#{obj2.hitBox.type}-#{obj1.hitBox.type}"

	if exports.tests[type1]?
		exports.tests[type1](obj1, obj2)
	else if exports.tests[type2]?
		exports.tests[type2](obj2, obj1)

	# Unknown hitBox types
	else
		null

exports.tests =

	'circle-circle': (obj1, obj2) ->
		r1 = obj1.hitBox.radius
		r2 = obj2.hitBox.radius

		# Zero or negative radius circles can not collide.
		return false if r1 <= 0 or r2 <= 0

		utils.distance(obj1.pos.x, obj1.pos.y, obj2.pos.x, obj2.pos.y) < r1 + r2

	'circle-segment': (obj1, obj2) ->
		c = {x: obj1.pos.x, y: obj1.pos.y}
		r = obj1.hitBox.radius
		a = obj2.hitBox.a
		b = obj2.hitBox.b

		# Zero or negative radius circles can not collide.
		return false if r <= 0

		# Zero length segments can not collide.
		return false if utils.vec.length(utils.vec.vector(a.x, a.y, b.x, b.y)) is 0

		ab = utils.vec.vector(a.x, a.y, b.x, b.y)
		ac = utils.vec.vector(a.x, a.y, c.x, c.y)
		abu = utils.vec.unit(ab)

		# Project AC onto AB.
		projLength = utils.vec.dot(ac, abu)
		proj = utils.vec.times(abu, projLength)

 		# Compute the closest point of AB from the circle.
		if projLength <= 0
			closest = a
		else if projLength >= utils.vec.length(ab)
			closest = b
		else
			closest = utils.vec.plus(a, proj)

		# Is the closest point of the segment inside of the circle?
		return utils.distance(closest.x, closest.y, c.x, c.y) < r

	'circle-multisegment': (obj1, obj2) ->
		points = obj2.hitBox.points

		# Multisegment with zero or one point can not collide.
		return false if points.length < 2

		# Zero or negative radius circles can not collide.
		return false if obj1.hitBox.radius <= 0

		for i in [0...points.length-1]
			mock =
				hitBox:
					a: {x: points[i].x, y: points[i].y}
					b: {x: points[i+1].x, y: points[i+1].y}
			return true if exports.tests['circle-segment'](obj1, mock)

		return false

	# From: http://paulbourke.net/geometry/lineline2d/
	'segment-segment': (obj1, obj2) ->
		a = obj1.hitBox.a
		b = obj1.hitBox.b
		c = obj2.hitBox.a
		d = obj2.hitBox.b

		# Zero length segments can not collide.
		return false if utils.vec.length(utils.vec.vector(a.x, a.y, b.x, b.y)) is 0
		return false if utils.vec.length(utils.vec.vector(c.x, c.y, d.x, d.y)) is 0

		denominator = (d.y-c.y)*(b.x-a.x)-(d.x-c.x)*(b.y-a.y)
		ua = ((d.x-c.x)*(a.y-c.y)-(d.y-c.y)*(a.x-c.x))
		ub = ((b.x-a.x)*(a.y-c.y)-(b.y-a.y)*(a.x-c.x))
	
		# Special case: the two segments are parallel.
		if denominator is 0

			# The segments are colinear, check for overlap.
			if ua is ub is 0

				# Check if point Z lies between X and Y.
				interior = (x, y, z) ->
					xy = utils.vec.vector(x.x, x.y, y.x, y.y)
					xyl2 = xy.x*xy.x+xy.y*xy.y
					return 0 <= ((x.y-z.y)*(x.y-y.y)-(x.x-z.x)*(y.x-x.x)) / xyl2 <= 1

				return interior(a, b, c) or
							 interior(a, b, d) or 
							 interior(c, d, a) or 
							 interior(c, d, b) 

			# The segments are not colinear, they can't touch.
			else
				return false

		# Classic case.
		else
			return 0 <= ua/denominator <= 1 and 0 <= ub/denominator <= 1

	'segment-multisegment': (obj1, obj2) ->
		points = obj2.hitBox.points

		# Multisegment with zero or one point can not collide.
		return false if points.length < 2

		for i in [0...points.length-1]
			mock =
				hitBox:
					a: {x: points[i].x, y: points[i].y}
					b: {x: points[i+1].x, y: points[i+1].y}
			return true if exports.tests['segment-segment'](obj1, mock)

		return false

	'multisegment-multisegment': (obj1, obj2) ->
		points = obj2.hitBox.points

		# Multisegment with zero or one point can not collide.
		return false if obj1.hitBox.points.length < 2 or points.length < 2

		for i in [0...points.length-1]
			mock =
				hitBox:
					a: {x: points[i].x, y: points[i].y}
					b:	{x: points[i+1].x, y: points[i+1].y}
			return true if exports.tests['segment-multisegment'](mock, obj1)

		return false

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
		bullet.explode()

		ddebug "bullet ##{bullet.id} destroyed bonus ##{bonus.id} and died"

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
