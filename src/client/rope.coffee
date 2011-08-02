class Rope
	constructor: (@client, rope) ->
		@serverUpdate(rope)

	serverUpdate: (rope) ->
		utils.deepMerge(rope, @)

	update: () ->
		@clientDelete = @serverDelete

	drawHitbox: (ctxt) ->
		points = @hitBox.points
		return if points.length < 2

		ctxt.strokeStyle = 'red'
		ctxt.lineWidth = 1.1
		ctxt.beginPath()
		ctxt.moveTo(points[0].x, points[0].y)
		for i in [1...points.length]
			ctxt.lineTo(points[i].x, points[i].y)
		ctxt.stroke()

	draw: (ctxt) ->
		# Draw a bezier curve passing through a set of points.
		# Partly borrowed from : http://www.efg2.com/Lab/Graphics/Jean-YvesQueinecBezierCurves.htm

		return if @chain.length is 0

		# Check for map warping.
		for i in [1...@chain.length]
			@chain[i] = @client.closestGhost(@chain[0], @chain[i])

		smooth = 0.75
		ctxt.strokeStyle = utils.color @color
		ctxt.lineWidth = 2
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

	explosionEffect: () ->
		return if @chain.length is 0

		# Convert the chain positions to the closest ghosts of the first node.
		for i in [1...@chain.length]
			@chain[i] = @client.closestGhost(@chain[0], @chain[i])

		# Compute the "center" of the rope.
		center = {x: 0, y: 0}
		for c in @chain
			center.x += c.x
			center.y += c.y
		center =
			x: center.x / @chain.length
			y: center.y / @chain.length

		# Compute edges so that they follow the curve of the rope and move
		# away from the center.
		edges = []
		for i in [0...@chain.length-1]
			pos =
				x: @chain[i].x + (@chain[i+1].x - @chain[i].x)/2
				y: @chain[i].y + (@chain[i+1].y - @chain[i].y)/2
			edges.push
				x: pos.x
				y: pos.y
				r: Math.atan2(@chain[i+1].y - @chain[i].y, @chain[i+1].x - @chain[i].x)
				vx: (pos.x - center.x) * 0.05
				vy: (pos.y - center.y) * 0.05
				vr: (Math.random()*2-1) * 0.05
				size: utils.distance(@chain[i].x, @chain[i].y, @chain[i+1].x, @chain[i+1].y)

		@client.effects.push new DislocateEffect(@client, edges, @color, 1000)

# Exports
window.Rope = Rope
