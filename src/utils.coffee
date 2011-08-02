exports ?= window.utils = {}

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Array and object utils.


# Return random array element.
Array.random = (array) ->
	array[Math.floor(Math.random() * array.length)]

# Return random object property.
exports.randomObjectElem = (obj) ->
	obj[ exports.Array.random(Object.keys(obj)) ]

# From jQuery
exports.isEmptyObject = (obj) ->
	for p of obj
		return false
	return true

# Return deep copy of obj.
# XXX: Only copies object and array properties deeply. Strings are
# immutable but other types might not be while not being flagged as
# 'object' by typeof.
exports.deepCopy = (obj, src = {}) ->
	copy = src
	for name, prop of obj
		if typeof prop is 'object' and not Array.isArray(prop)
			copy[name] = exports.deepCopy(prop, {})
		else if Array.isArray(prop)
			copy[name] = exports.deepCopy(prop, [])
		else
			copy[name] = prop

	return copy

# Merge `source' properties with `target' existing properties.
# No new property is created in `target'.
exports.safeDeepMerge = (source, target) ->
	for name, val of source
		# Only merge existing properties.
		if target[name]?

			# Recurse for object properties.
			if typeof target[name] is 'object' and not Array.isArray(target[name])
				exports.safeDeepMerge(source[name], target[name])
			else
				target[name] = val

	return target

# Put all `source' properties within `target', overwriting properties
# with the same name, and recursively calls deepMerge for object properties.
exports.deepMerge = (source, target) ->
	for name, val of source
		# Recurse for objects properties.
		if typeof source[name] is 'object' and not Array.isArray(source[name])
			target[name] = {} unless target[name]?
			exports.deepMerge(source[name], target[name])
		else
			target[name] = source[name]

	return target


#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Graphic utils.


# Stroke circle.
exports.strokeCircle = (ctxt, x, y, r) ->
	ctxt.beginPath()
	ctxt.arc(x, y, r, 2*Math.PI, false)
	ctxt.stroke()

# Color utils.

exports.color = (hsl, alpha = 1.0) ->
	'hsla(' + hsl[0] + ',' + hsl[1] + '%,' + hsl[2] + '%,' + alpha + ')'

exports.randomColor = () ->
	[Math.round(Math.random()*360), Math.round(40 + Math.random()*30), Math.round(20 + Math.random()*50)]

# Capitalize word.
exports.capitalize = (word) ->
	word[0].toUpperCase() + word.substring(1)

# Downcase word.
exports.downcase = (word) ->
	word[0].toLowerCase() + word.substring(1)

# Inexact floats have to be pretty-printed. The plan is to
# convert them using toFixed(2) for 2 decimal places.
# Integers stay as they are.
exports.prettyNumber = (str) ->
	isInt = (string) ->
		parseInt(string) == parseFloat(string)

	if isInt(str)
		str
	else
		parseFloat(str).toFixed(2)


#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Math and geometry utils.


# Stupid % operator.
exports.mod = (x, n) ->
	if isNaN(x)
		x
	else if x >= 0
		x%n
	else exports.mod(x+n, n)

# Euclidean distance between two points.
exports.distance = (x1, y1, x2, y2) ->
	Math.sqrt((x1-x2)*(x1-x2) + (y1-y2)*(y1-y2))

# Vector utils.
exports.vec =

	# Give a vector from [x1,y1] to [x2,y2].
	vector: (x1, y1, x2, y2) ->
		{x: x2-x1, y: y2-y1}

	# Give the length of v.
	length: (v) ->
		exports.distance(0, 0, v.x, v.y)

	# Give the unit vector of v.
	unit: (v) ->
		l = exports.vec.length(v)
		{x: v.x/l, y: v.y/l}

	# Give the dot product of u and v.
	dot: (u, v) ->
		u.x*v.x+u.y*v.y

	# Give v scaled by a scalar.
	times: (v, k) ->
		{x: v.x*k, y: v.y*k}

	# Give the sum of u and v.
	plus: (u, v) ->
		{x: u.x+v.x, y: u.y+v.y}

	# Give the difference of u and v.
	minus: (u, v) ->
		{x: u.x-v.x, y: u.y-v.y}

	# Give the perpendicular vector of v.
	perp: (v) ->
		{x: -v.y, y: v.x}

	# Give the vector v rotated by angle a.
	rotate: (v, a) ->
		cos = Math.cos(a)
		sin = Math.sin(a)
		{x: v.x*cos - v.y*sin, y: v.x*sin + v.y*cos}

# Transform a zero-width [A,B] segment to a polygon with given width.
exports.segmentToPoly = (A, B, width) ->
	# We need four points: translate [A,B] twice.
	# Once along its normal, once along its normal's opposite.
	N = exports.vec.times(exports.vec.unit(exports.vec.perp(exports.vec.minus(B, A))), width)
	oN = exports.vec.times(N, -1)

	return [
		exports.vec.plus(A, N),
		exports.vec.plus(B, N),
		exports.vec.plus(B, oN),
		exports.vec.plus(A, oN) ]

# Ensure 0 <= pos.{x,y} < s.
exports.warp = (pos, s) ->
	pos.x = exports.mod(pos.x, s)
	pos.y = exports.mod(pos.y, s)
	return pos

# Transform `pos2` so that it lies in the same frame of reference as
# `pos1`.
exports.unwarp = (pos1, pos2, s) ->
	hs = s/2
	dx = pos2.x - pos1.x
	dy = pos2.y - pos1.y

	if dx < -hs then pos2.x += s
	if dx > hs then pos2.x -= s
	if dy < -hs then pos2.y += s
	if dy > hs then pos2.y -= s

	return pos2

# Normalize angle between -pi and +pi.
exports.relativeAngle = (a) ->
	a = exports.mod(a, 2*Math.PI)

	if a > Math.PI
		a - 2*Math.PI
	else if a < -Math.PI
		a + 2*Math.PI
	else
		a

# Return acceleration vector from all gravity-emitting `objects',
# having center `source' and force `force'.
exports.gravityField = (pos, objects, source, force) ->
	{x: x1, y: y1} = pos

	# Apply gravity formula.
	gravity = ({x: x2, y: y2}, g) ->
		xt = x2-x1
		yt = y2-y1
		dist = xt*xt + yt*yt
		pull = g / (dist * Math.sqrt(dist))

		return {x: xt * pull, y: yt * pull}

	vx = vy = 0
	for id, obj of objects
		f = force(obj)

		unless f is 0
			pull = gravity(source(obj), f)

			# Increase field vector.
			vx += pull.x
			vy += pull.y

	return {x: vx, y: vy}
