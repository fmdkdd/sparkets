exports ?= window

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

# Stupid % operator.
exports.mod = (x, n) ->
	if isNaN(x)
		x
	else if x >= 0
		x%n
	else exports.mod(x+n, n)

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
	obj[ exports.randomArrayElem(Object.keys(obj)) ]

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

# Merge `obj' properties with `target' existing properties.
# No new property is created in `target'.
exports.safeDeepMerge = (target, obj) ->
	for name, val of obj
		# Only merge existing properties.
		if target[name]?

			# Recurse for object properties.
			if typeof target[name] is 'object' and not Array.isArray(target[name])
				exports.safeDeepMerge(target[name], obj[name])
			else
				target[name] = val

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
