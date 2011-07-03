class Rope
	constructor: (rope) ->
		@serverUpdate(rope)

	serverUpdate: (rope) ->
		for field, val of rope
			@[field] = val

	update: () ->
		@clientDelete = @serverDelete

	draw: (ctxt) ->
		# Draw a bezier curve passing through a set of points.
		# Partly borrowed from : http://www.efg2.com/Lab/Graphics/Jean-YvesQueinecBezierCurves.htm

		return if @chain.length is 0

		# Check for map warping.
		for i in [1...@chain.length]
			@chain[i] = closestGhost(@chain[0], @chain[i])

		smooth = 0.75
		ctxt.strokeStyle = color @color
		ctxt.globalCompositeOperation = 'destination-over'
		ctxt.beginPath()
		ctxt.moveTo(@chain[0].x, @chain[0].y)		

		for i in [0...@chain.length-1]
			prev = @chain[i-1] # Position of previous node.
			cur = @chain[i] # Position of current node.
			next = @chain[i+1] # Position of next node.
			nnext = @chain[i+2] # Position of next next node.

			# Compute a weighted symmetric to the previous node with respect
			# to the current one.
			if prev?
				sprev =
					x: cur.x - (prev.x - cur.x) * smooth / 2
					y: cur.y - (prev.y - cur.y) * smooth / 2
			else
				sprev =
					x: cur.x
					y: cur.y

			# Compute a weighted symmetric to the next next node with
			# respect to the next one.
			if nnext?
				snnext =
					x: next.x - (nnext.x - next.x) * smooth / 2
					y: next.y - (nnext.y - next.y) * smooth / 2
			else
				snnext =
					x: next.x
					y: next.y

			# Center of the current segment.
			middle = 
				x: cur.x + (next.x - cur.x) / 2
				y: cur.y + (next.y - cur.y) / 2

			# First control point : half of the distance between the first
			# symmetric and the middle point.
			cp1 =
				x: sprev.x + (middle.x - sprev.x) / 2
				y: sprev.y + (middle.y - sprev.y) / 2

			# Second control point : half of the distance between the second
			# symmetric and the middle point.
			cp2 =
				x: snnext.x + (middle.x - snnext.x) / 2
				y: snnext.y + (middle.y - snnext.y) / 2

			ctxt.bezierCurveTo(cp1.x, cp1.y, cp2.x, cp2.y, next.x, next.y)

		ctxt.stroke()

		ctxt.globalCompositeOperation = 'source-over'

	inView: (offset = {x:0, y:0}) ->
		true

# Exports
window.Rope = Rope
