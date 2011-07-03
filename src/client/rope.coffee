class Rope
	constructor: (rope) ->
		@serverUpdate(rope)

	serverUpdate: (rope) ->
		for field, val of rope
			@[field] = val

	update: () ->
		@clientDelete = @serverDelete

	draw: (ctxt) ->
		obj1 = window.gameObjects[@object1Id]
		obj2 = window.gameObjects[@object2Id]

		# Exit if one of the two linked object is destroyed.
		return if not obj1? or not obj2?

		# Draw a bezier curve passing through a set of points.
		# Partly borrowed from : http://www.efg2.com/Lab/Graphics/Jean-YvesQueinecBezierCurves.htm

		# Build a chain of objects and nodes, then convert them to closest positions.
		chain = [window.gameObjects[@object1Id]].concat(@nodes).concat([window.gameObjects[@object2Id]])
		for i in [1...chain.length]
			chain[i] = closestGhost(chain[0].pos, chain[i].pos)
		chain[0] = chain[0].pos

		smooth = 0.75
		ctxt.strokeStyle = 'black'
		ctxt.beginPath()
		ctxt.moveTo(chain[0].x, chain[0].y)		

		x = Math.random() < 0.05
		for i in [0...chain.length-1]
			prev = chain[i-1] # Position of previous node.
			cur = chain[i] # Position of current node.
			next = chain[i+1] # Position of next node.
			nnext = chain[i+2] # Position of next next node.

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
			if x then console.log i+' '+cur.y+' '+next.y
		ctxt.stroke()

	inView: (offset = {x:0, y:0}) ->
		true

# Exports
window.Rope = Rope
