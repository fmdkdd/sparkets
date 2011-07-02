class Rope
	constructor: (rope) ->
		@serverUpdate(rope)

	serverUpdate: (rope) ->
		for field, val of rope
			@[field] = val

	update: () ->
		@clientDelete = @serverDelete

	draw: (ctxt) ->
		chain = [window.gameObjects[@object1Id]].concat(@nodes).concat([window.gameObjects[@object2Id]])

		# Draw lines from neighbor to neighbor.
		for i in [0...chain.length-1]
			cur = chain[i]
			next = chain[i+1]
			ctxt.beginPath()
			ctxt.moveTo(cur.pos.x, cur.pos.y)
			g = closestGhost(cur.pos, next.pos)
			console.info g
			ctxt.lineTo(g.x, g.y)
			ctxt.stroke()

	inView: (offset = {x:0, y:0}) ->
		true

# Exports
window.Rope = Rope
