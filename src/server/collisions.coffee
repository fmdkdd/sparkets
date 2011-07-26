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

# Subdivide a hitbox into convex hitboxes.
exports.convexHitboxes = (box) ->
	switch box.type

		# Circles are always convex.
		when 'circle'
			[box]

		# Each subsegment becomes a unique hitbox.
		when 'segments'
			segments = []
			if box.points.length >= 2
				for i in [0...box.points.length-1]
					segments.push
						type: 'segments'
						points: [box.points[i], box.points[i+1]]
			segments

		when 'polygon'
			polys = []
			if box.points.length >= 2
				polys.push box # TODO when necesary
			polys

		# Unknown hitbox type.
		else
			null

# Check that the hitbox is valid.
exports.validHitbox = (box) ->
	switch box.type

		when 'circle'
			# Zero radius circles cannot collide.
			return false if box.radius <= 0

		when 'segments'
			# Empty segments cannot collide.
			return false if box.points.length isnt 2

			# Zero length segments cannot collide
			a = box.points[0]
			b = box.points[1]
			return false if a.x is b.x and a.y is b.y

	return true

# Project a hitbox onto an axis.
exports.projectHitBox = (box, axis) ->
	proj = {min: +Infinity, max: -Infinity}

	switch box.type

		when 'circle'
			center = {x: box.x, y: box.y}
			x = utils.vec.dot(axis, center)
			proj.min = x - box.radius
			proj.max = x + box.radius

		when 'segments', 'polygon'
			for p in box.points
				x = utils.vec.dot(axis, p)
				proj.min = x if x < proj.min
				proj.max = x if x > proj.max

	return proj

# Check if two projections overlap.
exports.projectionsOverlap = (proj1, proj2) ->
	return proj1.min <= proj2.min <= proj1.max or
				 proj1.min <= proj2.max <= proj1.max or
		     proj2.min <= proj1.min <= proj2.max or
				 proj2.min <= proj1.max <= proj2.max

# Give possible separating axes based on the hitboxes features.
exports.separatingAxes = (box1, box2) ->
	axes = []

	for b in [box1, box2]
		switch b.type

			# Add the axis joining the circle center and the cloest vertex
			# of the other hitbox.
			when 'circle'
				center = {x: b.x, y: b.y}
				ob = (if b is box1 then box2 else box1)

				# Compute the closest vertex.
				if ob.type is 'circle'
					closest = {x: ob.x, y: ob.y}
				else
					# TODO : use Voronoi regions instead of dumb distances.
					closest = ob.points[0]
					distClosest = utils.distance(closest.x, closest.y, center.x, center.y)
					for i in [1...ob.points.length]
						dist = utils.distance(ob.points[i].x, ob.points[i].y, center.x, center.y)
						if dist < distClosest
							closest = ob.points[i]
							distClosest = dist

				# Only add the axis if it has a length.
				if closest.x isnt center.x or closest.y isnt center.y
					axes.push utils.vec.normalize(utils.vec.minus(closest, center))

			# Add the normal axis to the edge (there should be only one edge
			# as the segments have been subdivided into convex parts beforehand)
			when 'segments'
				edge = utils.vec.minus(b.points[1], b.points[0])
				axes.push utils.vec.normalize(utils.vec.perp(edge))

			# Add the normal axis to each edge.
			when 'polygon'
				for i in [0...b.points.length]
					e1 = b.points[i]
					e2 = b.points[(i+1) % b.points.length]
					edge = utils.vec.minus(e2, e1)
					axes.push utils.vec.normalize(utils.vec.perp(edge))

	return axes

# Check for intersection between two hitboxes.
exports.checkIntersection = (box1, box2) ->

	# Check that the hitboxes are valid.
	return false if not exports.validHitbox(box1) or not exports.validHitbox(box2)

	# Get possible separating axes.
	axes = exports.separatingAxes(box1, box2)

	# Project the hitboxes onto each axis.
	for a in axes

		p1 = exports.projectHitBox(box1, a)
		p2 = exports.projectHitBox(box2, a)

		# If there is no overlap, we found a separating axis.
		return false if not exports.projectionsOverlap(p1, p2)

	# No separating axis, intersection detected.
	return true

exports.test = (box1, box2, offset1, offset2) ->

	# Apply offsets.
	box1 = exports.addOffset(utils.deepCopy(box1), offset1) if offset1?
	box2 = exports.addOffset(utils.deepCopy(box2), offset2) if offset2?

	# Subdivide hitboxes into convex ones.
	boxes1 = exports.convexHitboxes(box1)
	boxes2 = exports.convexHitboxes(box2)

	# Check for unknown hitbox types.
	return null if not boxes1? or not boxes2?

	# Check each hitboxes pair for intersection.
	for b1 in boxes1
		for b2 in boxes2
			return true if exports.checkIntersection(b1, b2)

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

			ship1.addStat('kills', 1)
			ddebug "ship ##{ship1.id} boosted through ship ##{ship2.id}"

		# Ship2 has boost, not ship1.
		else if boost2 and not boost1
			ship1.explode()
			ship1.killingAccel = ship2.vel

			ship2.addStat('kills', 1)
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

	'shield-bullet': (shield, bullet) ->
		# shields absorb all bullets, except from the user!
		bullet.explode() if bullet.state is 'active' and bullet.owner isnt shield.ship

		ddebug "shield ##{shield.id} hit bullet ##{bullet.id}"

	'shield-shield': (shield1, shield2) ->
		# shields cancel each other.
		shield1.cancel()
		shield2.cancel()

		ddebug "shield ##{shield1.id} hit shield ##{shield2.id}"

	'shield-mine': (shield, mine) ->
		# shields absorb one mine.
		mine.explode() if mine.state is 'active'
		shield.cancel()
		ddebug "shield ##{shield.id} hit mine ##{mine.id}"

	# shields do not save ships from moons or planets ...

	'shield-ship': (shield, ship) ->
		# shields can't take more than one ship.
		if shield.ship isnt ship
			ship.explode()
			shield.cancel()

			shield.ship.addStat('kills', 1)

		ddebug "shield ##{shield.id} hit ship ##{ship.id}"

	'shield-tracker': (shield, tracker) ->
		# shields absorb one tracker.
		tracker.explode()
		shield.cancel()

		ddebug "shield ##{shield.id} hit tracker ##{tracker.id}"

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
		# Release bonus on ship, if the rope is attached.
		if rope.object1?.type is 'ship'
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
