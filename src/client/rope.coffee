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
		for i in [0...chain.length-1]
			cur = chain[i]
			next = chain[i+1]
			ctxt.beginPath()
			ctxt.moveTo(cur.pos.x, cur.pos.y)
			g = closestGhost(cur.pos, next.pos)
			ctxt.lineTo(g.x, g.y)
			ctxt.stroke()

	inView: (offset = {x:0, y:0}) ->
		true

# Exports
window.Rope = Rope
