exports ?= window

# Console output shortcuts.

exports.log = (msg) ->
	console.log msg

exports.info = (msg) ->
	console.info msg

exports.warn = (msg) ->
	console.warn msg

exports.log = (msg) ->
	console.error msg

# Array extension

Array.max = (array) ->
	Math.max.apply(Math, array)

Array.min = (array) ->
	Math.min.apply(Math, array)

# Euclidean distance between two points.
exports.distance = (x1, y1, x2, y2) ->
	Math.sqrt((x1-x2)*(x1-x2) + (y1-y2)*(y1-y2))

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
	if x > 0 then x%n else exports.mod(x+n, n)

# Random element in array.
exports.randomElem = (array) ->
	array[Math.round(Math.random() * (array.length-1))]

# Stroke circle.
exports.strokeCircle = (ctxt, x, y, r) ->
	ctxt.beginPath()
	ctxt.arc(x, y, r, 2*Math.PI, false)
	ctxt.stroke()

# Color utils.

exports.color = (hsl, alpha = 1.0) ->
	'hsla(' + hsl[0] + ',' + hsl[1] + '%,' + hsl[2] + '%,' + alpha + ')'

exports.randomColor = () ->
	[Math.round(Math.random()*360), 100, Math.round(20 + Math.random()*50)]
