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

		chain = [window.gameObjects[@object1Id]].concat(@nodes).concat([window.gameObjects[@object2Id]])

		# Draw lines from neighbor to neighbor.
		ctxt.beginPath()
		ctxt.moveTo(chain[0].pos.x, chain[0].pos.y)		
		for i in [0...chain.length-1]
			cur = chain[i]
			next = chain[i+1]
			nnext = chain[i+2]
			ctxt.strokeRect(cur.pos.x, cur.pos.y, 3,3)
			g = closestGhost(cur.pos, next.pos)

			# Use a quadratic curve to smooth the rope.
			if nnext?
				a = Math.atan2(nnext.pos.y - next.pos.y, nnext.pos.x - next.pos.x) 
				a += Math.PI
				cp =
					x: next.pos.x + 20 * Math.cos(a)
					y: next.pos.y + 20 * Math.sin(a)
				if i is 0 then ctxt.strokeRect(cp.x, cp.y, 3,3)
				ctxt.quadraticCurveTo(cp.x, cp.y, g.x, g.y)
			else
				ctxt.lineTo(next.pos.x, next.pos.y)

		ctxt.stroke()

	inView: (offset = {x:0, y:0}) ->
		true

# Exports
window.Rope = Rope
