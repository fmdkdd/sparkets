exports ?= window.utils = {}

# Array extension

Array.max = (array) ->
	Math.max.apply(Math, array)

Array.min = (array) ->
	Math.min.apply(Math, array)

Array.random = (array) ->
	return array[Math.floor(Math.random() * array.length)]

# Euclidean distance between two points.
exports.distance = (x1, y1, x2, y2) ->
	Math.sqrt((x1-x2)*(x1-x2) + (y1-y2)*(y1-y2))

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

	# Give the normalized vector v.
	normalize: (v) ->
		l = exports.vec.length(v)
		{x: v.x/l, y: v.y/l}

	rotate: (v, a) ->
		cos = Math.cos(a)
		sin = Math.sin(a)
		{x: v.x*cos - v.y*sin, y: v.x*sin + v.y*cos}

# Return intersection point between line AB and circle (Cx,Cy,Cr).
exports.lineInterCircle = (Ax,Ay, Bx,By, r, Cx,Cy,Cr, gap) ->
	[ABx, ABy] = [Bx-Ax, By-Ay]
	steps = exports.distance(Ax, Ay, Bx, By) / gap

	for i in [0..steps]
		alpha = i/steps
		[Dx, Dy] = [Ax + alpha*ABx, Ay + alpha*ABy]
		return [Dx, Dy] if exports.distance(Dx, Dy, Cx, Cy) < r + Cr
	return null

# From jQuery
exports.isEmptyObject = (obj) ->
	for p of obj
		return false
	return true

exports.deepCopy = (obj) ->
	copy = {}
	for name, prop of obj
		if typeof prop is 'object' and not Array.isArray(prop)
			copy[name] = exports.deepCopy(prop)
		else
			copy[name] = prop

	return copy

# Stupid % operator.
exports.mod = (x, n) ->
	if isNaN(x)
		x
	else if x >= 0
		x%n
	else exports.mod(x+n, n)

exports.warp = (pos, n) ->
   pos.x = exports.mod(pos.x, n)
   pos.y = exports.mod(pos.y, n)
   return pos

# Normalize angle between -Pi and +Pi.
exports.relativeAngle = (a) ->
	a = exports.mod(a, 2*Math.PI)

	if a > Math.PI
		a - 2*Math.PI
	else if a < -Math.PI
		a + 2*Math.PI
	else
		a

exports.randomObjectElem = (obj) ->
	obj[ exports.Array.random(Object.keys(obj)) ]

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

# Uppercase first letter of word.
exports.capitalize = (word) ->
	word[0].toUpperCase() + word.substring(1)

# Lowerize (???) first letter of word.
exports.lowerize = (word) ->
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
		pull = gravity(source(obj), force(obj))

		# Increase field vector.
		vx += pull.x
		vy += pull.y

	return {x: vx, y: vy}

# Mixins utils from:
# https://github.com/jashkenas/coffee-script/wiki/FAQ
exports.extend = (obj, mixin) ->
  for name, method of mixin
    obj[name] = method

exports.include = (klass, mixin) ->
  exports.extend(klass.prototype, mixin)
