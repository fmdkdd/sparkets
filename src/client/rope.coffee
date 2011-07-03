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

		chain = [window.gameObjects[@object1Id]].concat(@nodes).concat([window.gameObjects[@object2Id]])

		smooth = 0.75
		ctxt.strokeStyle = 'black'
		ctxt.beginPath()
		ctxt.moveTo(chain[0].pos.x, chain[0].pos.y)		

		for i in [0...chain.length-1]
			prev = chain[i-1] # Previous node.
			cur = chain[i] # Current node.
			next = chain[i+1] # Next node.
			nnext = chain[i+2] # Node after the next node.

			# Compute a weighted symmetric to the previous node with respect
			# to the current one.
			if prev?
				sprev =
					x: cur.pos.x - (prev.pos.x - cur.pos.x) * smooth / 2
					y: cur.pos.y - (prev.pos.y - cur.pos.y) * smooth / 2
			else
				sprev =
					x: cur.pos.x
					y: cur.pos.y

			# Compute a weighted symmetric to the nnext node with respect to
			# the next one.
			if nnext?
				snnext =
					x: next.pos.x - (nnext.pos.x - next.pos.x) * smooth / 2
					y: next.pos.y - (nnext.pos.y - next.pos.y) * smooth / 2
			else
				snnext =
					x: next.pos.x
					y: next.pos.y

			# Center of the current segment.
			middle = 
				x: cur.pos.x + (next.pos.x - cur.pos.x) / 2
				y: cur.pos.y + (next.pos.y - cur.pos.y) / 2

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

			ctxt.bezierCurveTo(cp1.x, cp1.y, cp2.x, cp2.y, next.pos.x, next.pos.y)

		ctxt.stroke()

	inView: (offset = {x:0, y:0}) ->
		true

# Exports
window.Rope = Rope
