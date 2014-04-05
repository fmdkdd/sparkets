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

		when 'polygon'
			# Empty polygons cannot collide.
			return false if box.points.length < 2

		# Unknown hitbox type
		else
			return false

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

# Count possible separating axes.
exports.countSeparatingAxes = (box) ->
	switch box.type
		when 'circle'
			1
		when 'segments'
			box.points.length-1
		when 'polygon'
			box.points.length
		else
			0

# Give the ith separating axis of the box1-box2 pair.
exports.separatingAxis = (box1, box2, i) ->

	# To which hitbox does the separating axis belong?
	box = if i < box1.count then box1 else box2

	switch box.type

		# Add the axis joining the circle center and the closest vertex
		# of the other hitbox.
		when 'circle'
			center = {x: box.x, y: box.y}
			other = (if box is box1 then box2 else box1)

			# Compute the closest vertex.
			if other.type is 'circle'
				closest = {x: other.x, y: other.y}
			else
				# TODO : use Voronoi regions instead of dumb distances.
				closest = other.points[0]
				distClosest = utils.distance(closest.x, closest.y, center.x, center.y)
				for j in [1...other.points.length]
					dist = utils.distance(other.points[j].x, other.points[j].y, center.x, center.y)
					if dist < distClosest
						closest = other.points[j]
						distClosest = dist

			# Only return the axis if it has a length.
			if closest.x isnt center.x or closest.y isnt center.y
				utils.vec.unit(utils.vec.minus(closest, center))

		# Add the normal axis to the edge (there should be only one edge
		# as the segments have been subdivided into convex parts beforehand)
		when 'segments'
			edge = utils.vec.minus(box.points[1], box.points[0])
			utils.vec.unit(utils.vec.perp(edge))

		# Add the normal axis to each edge.
		when 'polygon'
			offset = if i < box1.count then 0 else box1.count
			e1 = box.points[i-offset]
			e2 = box.points[(i+1-offset) % box.points.length]

			edge = utils.vec.minus(e2, e1)
			utils.vec.unit(utils.vec.perp(edge))

# Check for intersection between two hitboxes.
exports.checkIntersection = (box1, box2) ->


	# Check that the hitboxes are valid.
	return false if not exports.validHitbox(box1) or not exports.validHitbox(box2)

	# Count possible separating axes.
	box1.count = exports.countSeparatingAxes(box1)
	box2.count = exports.countSeparatingAxes(box2)

	for i in [0...(box1.count+box2.count)]

		# Compute the ith separating axis.
		axis = exports.separatingAxis(box1, box2, i)

		continue if not axis?

		# Project the hitboxes onto the axis.
		p1 = exports.projectHitBox(box1, axis)
		p2 = exports.projectHitBox(box2, axis)

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
 	 		ship.holdBonus(bonus)
			ship.addStat("#{bonus.type} bonus grabs", 1)

			ddebug "ship ##{ship.id} picked up #{bonus.bonusType} bonus ##{bonus.id}"

	'ship-bullet': (ship, bullet) ->
		if ship.state is 'alive' and
				bullet.state is 'active' and
				(ship.id isnt bullet.owner.id or
				bullet.elapsedMoves > 3)

			ship.explode(bullet)
			bullet.explode()

			if bullet.owner isnt ship
				bullet.owner.addStat('kills', 1)
				bullet.owner.addStat('bullet kills', 1)
			else
				ship.addStat('deaths by own bullet', 1)
			ship.addStat('bullet deaths', 1)

			ship.game.events.push
				type: 'ship killed'
				idKilled: ship.id
				idKiller: bullet.owner.id

			ddebug "bullet ##{bullet.id} killed ship ##{ship.id}"

	'ship-mine': (ship, mine) ->
		# Stealthy ships are undetected!
		return if ship.invisible

		ship.explode()
		mine.explode() if mine.state is 'active'

		if mine.owner isnt ship
			mine.owner.addStat('kills', 1)
			mine.owner.addStat('mine kills', 1)
		else
			ship.addStat('deaths by own mine', 1)
		ship.addStat('mine deaths', 1)

		ship.game.events.push
			type: 'ship killed'
			idKilled: ship.id
			idKiller: mine.owner.id

		ddebug "mine ##{mine.id} killed ship ##{ship.id}"

	'ship-grenade': (ship, grenade) ->

		ship.explode()
		grenade.explode() if grenade.state is 'active'

		if grenade.owner isnt ship
			grenade.owner.addStat('kills', 1)
			grenade.owner.addStat('mine kills', 1)
		else
			ship.addStat('deaths by own grenade', 1)
		ship.addStat('grenade deaths', 1)

		ship.game.events.push
			type: 'ship killed'
			idKilled: ship.id
			idKiller: grenade.owner.id

		ddebug "grenade ##{grenade.id} killed ship ##{ship.id}"

	'ship-moon': (ship, moon) ->
		ship.explode()

		ship.game.events.push
			type: 'ship crashed'
			id: ship.id

		ship.addStat('moon crashes', 1)

		ddebug "ship ##{ship.id} crashed on moon ##{moon.id}"

	'ship-planet': (ship, planet) ->
		ship.explode()

		ship.game.events.push
			type: 'ship crashed'
			id: ship.id

		ship.addStat('planet crashes', 1)

		ddebug "ship ##{ship.id} crashed on planet ##{planet.id}"

	'ship-ship': (ship1, ship2) ->
		# Boost bonus grants immunity except when both have it.
		boost1 = ship1.boost > 1
		boost2 = ship2.boost > 1

		# Ship1 has boost, not ship2.
		if boost1 and not boost2
			ship2.explode(ship1)

			ship1.addStat('kills', 1)
			ship1.addStat('boost kills', 1)
			ship2.addStat('boost deaths', 1)

			ship1.game.events.push
				type: 'ship killed'
				idKilled: ship2.id
				idKiller: ship1.id

			ddebug "ship ##{ship1.id} boosted through ship ##{ship2.id}"

		# Ship2 has boost, not ship1.
		else if boost2 and not boost1
			ship1.explode(ship2)

			ship2.addStat('kills', 1)
			ship2.addStat('boost kills', 1)
			ship1.addStat('boost deaths', 1)

			ship1.game.events.push
				type: 'ship killed'
				idKilled: ship1.id
				idKiller: ship2.id

			ddebug "ship ##{ship2.id} boosted through ship ##{ship1.id}"

		# Both or none have boost.
		else
			ship1.explode(ship2)
			ship2.explode(ship1)

			ship1.addStat('ship crashes', 1)
			ship2.addStat('ship crashes', 1)

			ship1.game.events.push
				type: 'ships both crashed'
				id1: ship1.id
				id2: ship2.id

			ddebug "ship ##{ship1.id} and ship ##{ship2.id} crashed"

	'ship-rope': (ship, rope) ->
		# Boosted ships steal the bonus if not already carrying one
		if rope.holder? and
				rope.holder isnt ship and
				ship.boost > 1 and
				not ship.bonus?
			bonus = rope.holdee
			rope.holder.releaseBonus()
			ship.holdBonus(bonus)

			ship.addStat('bonuses stolen under boost', 1)

	'bullet-moon': (bullet, moon) ->
		if bullet.state is 'active'
			bullet.explode()

			bullet.owner.addStat('bullets crashed on moons', 1)

		ddebug "bullet ##{bullet.id} hit moon ##{moon.id}"

	'bullet-planet': (bullet, planet) ->
		if bullet.state is 'active'
			bullet.explode()

			bullet.owner.addStat('bullets crashed on planets', 1)

		ddebug "bullet ##{bullet.id} hit planet ##{planet.id}"

	'shield-bullet': (shield, bullet) ->
		# shields absorb all bullets, except from the user!
		if bullet.state is 'active'
			bullet.explode()

			shield.owner.addStat('bullets absorbed with shield', 1)
			bullet.owner.addStat('bullets lost to shields', 1)

		ddebug "shield ##{shield.id} hit bullet ##{bullet.id}"

	'shield-shield': (shield1, shield2) ->
		shield1.owner.addStat('shield on shield collisions', 1)
		shield2.owner.addStat('shield on shield collisions', 1)

		ddebug "shield ##{shield1.id} hit shield ##{shield2.id}"

	'shield-mine': (shield, mine) ->
		# shields absorb one mine.
		mine.explode() if mine.state is 'active'
		shield.cancel()

		shield.owner.addStat('mines absorbed with shield', 1)

		ddebug "shield ##{shield.id} hit mine ##{mine.id}"

	'shield-tracker': (shield, tracker) ->
		# shields absorb one tracker.
		tracker.explode() if tracker.state isnt 'exploding'
		shield.cancel()

		shield.owner.addStat('trackers absorbed with shield', 1)
		tracker.owner.addStat('trackers lost to shields', 1)

		ddebug "shield ##{shield.id} hit tracker ##{tracker.id}"

	'mine-bullet': (mine, bullet) ->
		if mine.state is 'active'
			mine.explode()

			bullet.owner.addStat('mines exploded with bullets', 1)

		ddebug "bullet ##{bullet.id} hit mine ##{mine.id}"

	'mine-moon': (mine, moon) ->
		if mine.state is 'active'
			mine.explode()

			mine.owner.addStat('mines lost to moons', 1)

		ddebug "bullet ##{mine.id} hit moon ##{moon.id}"

	'mine-mine': (mine1, mine2) ->
		# Only exploding mines trigger other mines.
		if mine2.state is 'exploding' and mine1.state is 'active'
			mine1.explode()
			ddebug "mine ##{mine2.id} triggered mine ##{mine1.id}"

		if mine1.state is 'exploding' and mine2.state is 'active'
			mine2.explode()
			ddebug "mine ##{mine1.id} triggered mine ##{mine2.id}"

	'mine-bonus': (mine, bonus) ->
		bonus.explode()
		mine.explode()

		mine.owner.addStat('bonuses destroyed with mines', 1)

		ddebug "mine ##{mine.id} destroyed bonus ##{bonus.id}"

	'bullet-bullet': (bullet1, bullet2) ->
		bullet1.explode()
		bullet2.explode()

		bullet1.owner.addStat('bullets collisions', 1)
		bullet2.owner.addStat('bullets collisions', 1)

		ddebug "bullet ##{bullet1.id} and bullet ##{bullet2.id} collided"

	'bullet-bonus': (bullet, bonus) ->
		bonus.explode()
		bullet.explode()

		bullet.owner.addStat('bonus destroyed with bullets', 1)

		ddebug "bullet ##{bullet.id} destroyed bonus ##{bonus.id} and died"

	'bullet-rope': (bullet, rope) ->
		# Release bonus on ship, if the rope is attached.
		if rope.holder?.type is 'ship'
			rope.holder.releaseBonus()

			bullet.owner.addStat('bonuses detached', 1)

		ddebug "bullet ##{bullet.id} cut rope ##{rope.id}"

	'bonus-planet': (bonus, planet) ->
		bonus.explode()

		ddebug "bonus ##{bonus.id} crashed on planet ##{planet.id}"

	'bonus-moon': (bonus, moon) ->
		bonus.explode()

		ddebug "bonus ##{bonus.id} crashed on moon ##{moon.id}"

	'tracker-planet' : (tracker, planet) ->
		tracker.explode() if tracker.state isnt 'exploding'

		tracker.owner.addStat('trackers lost to planets', 1)

		ddebug "tracker ##{tracker.id} crashed on planet ##{planet.id}"

	'tracker-moon' : (tracker, moon) ->
		tracker.explode() if tracker.state isnt 'exploding'

		tracker.owner.addStat('trackers lost to moons', 1)

		ddebug "tracker ##{tracker.id} crashed on moon ##{moon.id}"

	'tracker-ship' : (tracker, ship) ->
		tracker.explode() if tracker.state isnt 'exploding'
		ship.explode(tracker)

		if tracker.owner isnt ship
			tracker.owner.addStat('kills', 1)
			tracker.owner.addStat('tracker kills', 1)
		else
			ship.addStat('deaths by own tracker', 1)
		ship.addStat('tracker deaths', 1)

		ship.game.events.push
			type: 'ship killed'
			idKilled: ship.id
			idKiller: tracker.owner.id

		ddebug "tracker ##{tracker.id} destroyed ship ##{ship.id}"

	'tracker-bullet' : (tracker, bullet) ->
		tracker.explode() if tracker.state isnt 'exploding'
		bullet.explode()

		tracker.owner.addStat('trackers lost to bullets', 1)
		bullet.owner.addStat('trackers shot with bullets', 1)

		ddebug "bullet ##{bullet.id} destroyed tracker ##{tracker.id}"

	'tracker-mine' : (tracker, mine) ->
		tracker.explode() if tracker.state isnt 'exploding'
		mine.explode()

		tracker.owner.addStat('trackers lost to mines', 1)
		mine.owner.addStat('trackers destroyed with mines', 1)

		ddebug "mine ##{mine.id} destroyed tracker ##{tracker.id}"

	'grenade-moon': (grenade, moon) ->
		if grenade.state is 'active'
			grenade.explode()
			grenade.fragment()

		ddebug "grenade ##{grenade.id} hit moon ##{moon.id}"

	'grenade-planet': (grenade, planet) ->
		if grenade.state is 'active'
			grenade.explode()
			grenade.fragment()

		ddebug "grenade ##{grenade.id} hit planet ##{planet.id}"

	'EMP-ship': (emp, ship) ->

		return if emp.owner.id is ship.id

		ship.drunkEffect()

		if ship.invisible
			ship.invisible = no
			ship.flagNextUpdate('invisible')

		ddebug "EMP ##{emp.id} hit ship ##{ship.id}"

	'EMP-bullet': (emp, bullet) ->
		bullet.explode()

		ddebug "EMP ##{emp.id} destroyed bullet ##{bullet.id}"

	'EMP-mine': (emp, mine) ->
		mine.explode()

		ddebug "EMP ##{emp.id} destroyed mine ##{mine.id}"

	'EMP-tracker': (emp, tracker) ->
		tracker.explode() if tracker.state isnt 'exploding'

		ddebug "EMP ##{emp.id} destroyed tracker ##{tracker.id}"

	'EMP-shield': (emp, shield) ->
		shield.cancel()

		ddebug "EMP ##{emp.id} cancelled shield ##{shield.id}"
