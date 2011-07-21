utils = require '../utils'
logger = require('../logger').static

ddebug = (msg) -> logger.log 'collisions', msg

exports.addOffset = (box, offset) ->
	switch box.type
		when 'circle'
			box.x += offset.x
			box.y += offset.y

		when 'segments', 'polygon'
			for p in box.points
				p.x += offset.x
				p.y += offset.y

	return box

# Check intersection between two hitboxes with the help of a set of
#	possible separating axes.
exports.checkIntersection = (box1, box2, axes) ->

	# Project a hitbox onto an axis.
	projectHitBox = (box, axis) ->
		proj = {min: +Infinity, max: -Infinity}
		for p in box.points
			x = utils.vec.dot(axis, p)
			proj.min = x if x < proj.min
			proj.max = x if x > proj.max
		return proj

	# Check if the projection of two objects onto an axis overlap.
	projectionsOverlap = (box1, box2, axis) ->
		proj1 = projectHitBox(box1, axis)
		proj2 = projectHitBox(box2, axis)
		return proj1.min <= proj2.min <= proj1.max or
					 proj1.min <= proj2.max <= proj1.max or
			     proj2.min <= proj1.min <= proj2.max or
					 proj2.min <= proj1.max <= proj2.max

	# Check if a separating axis exists.
	for a in axes
		return false if not projectionsOverlap(box1, box2, a)

	# No separating axis, intersection.
	return true

# Give the axis of the edges of a hitbox.
exports.edgesAxes = (box) ->
	axes = []

	points = box.points
	for i in [0...points.length]
		a = points[i]
		b = points[(i+1)%points.length]
		e = utils.vec.vector(a.x, a.y, b.x, b.y)
		axes.push utils.vec.normalize(e)	

	return axes

exports.test = (box1, box2, offset1, offset2) ->
	box1 = exports.addOffset(utils.deepCopy(box1), offset1) if offset1?
	box2 = exports.addOffset(utils.deepCopy(box2), offset2) if offset2?

	type1 = "#{box1.type}-#{box2.type}"
	type2 = "#{box2.type}-#{box1.type}"

	if exports.tests[type1]?
		exports.tests[type1](box1, box2)
	else if exports.tests[type2]?
		exports.tests[type2](box2, box1)

	# Unknown hitBox types
	else
		null

exports.tests =

	'circle-circle': (box1, box2) ->
		r1 = box1.radius
		r2 = box2.radius

		# Zero or negative radius circles can not collide.
		return false if r1 <= 0 or r2 <= 0

		utils.distance(box1.x, box1.y, box2.x, box2.y) < r1 + r2

	'circle-segments': (box1, box2) ->
		c = {x: box1.x, y: box1.y}
		r = box1.radius

		# Zero or negative radius circles can not collide.
		return false if r <= 0

		points = box2.points

		# Segments with no point can not collide.
		return false if points.length is 0

		# Test each segment against the circle.
		for i in [0...points.length-1]
			a = points[i]
			b = points[i+1]

			# Zero length segments can not collide.
			return false if a.x is b.x and a.y is b.y

			ab = utils.vec.minus(b, a)
			ac = utils.vec.minus(c, a)
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
			return true if utils.distance(closest.x, closest.y, c.x, c.y) < r

		return false

	'circle-polygon': (box1, box2) ->

	'segments-segments': (box1, box2) ->
		points1 = box1.points
		points2 = box2.points

		# Segments with no point can not collide.
		return false if points1.length is 0
		return false if points2.length is 0

		for i in [0...points1.length-1]
			a = points1[i]
			b = points1[i+1]

			# Zero length segments can not collide.
			continue if a.x is b.x and a.y is b.y

			for j in [0...points2.length-1]
				c = points2[j]
				d = points2[j+1]

				# Zero length segments can not collide.
				continue if c.x is d.x and c.y is d.y

				# Possible separating axes are the edges axes and the normals
				# to the edges axes.
				axes1 = exports.edgesAxes(box1)
				axes2 = exports.edgesAxes(box2)
				axes = axes1.concat(axes2)
				for i in [0...axes.length]
					axes.push utils.vec.perp(axes[i])

				return true if exports.checkIntersection(box1, box2, axes)

		return false

	'segments-polygon': (box1, box2) ->

	'polygon-polygon': (box1, box2) ->

		# Possible separating axes are the normals to the edges.
		axes1 = exports.edgesAxes(box1)
		axes2 = exports.edgesAxes(box2)
		axes = axes1.concat(axes2)
		for a in axes
			a = utils.vec.perp(a)

		return exports.checkIntersection(box1, box2, axes)

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

	'bullet-rope': (bullet, rope) ->
		# Release bonus on ship.
		if rope.object1.type is 'ship'
			rope.object1.releaseBonus()

		ddebug "bullet ##{bullet.id} cut rope ##{rope.id}"

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
