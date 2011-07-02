class Rope
	constructor: (rope) ->
		@serverUpdate(rope)

	serverUpdate: (rope) ->
		for field, val of rope
			@[field] = val

	update: () ->
		@clientDelete = @serverDelete

	draw: (ctxt) ->
		# Draw a line from the first object to the first node.
		obj1 = window.gameObjects[@object1Id]
		ctxt.beginPath()
		ctxt.moveTo(obj1.pos.x, obj1.pos.y)
		ctxt.lineTo(@nodes[0].pos.x, @nodes[0].pos.y)
		ctxt.stroke()

		# Draw a line from the second object to the last node.
		obj2 = window.gameObjects[@object2Id]
		ctxt.beginPath()
		ctxt.moveTo(obj2.pos.x, obj2.pos.y)
		ctxt.lineTo(@nodes[@nodes.length-1].pos.x, @nodes[@nodes.length-1].pos.y)
		ctxt.stroke()

		for i in [0...@nodes.length-1]
			cur = @nodes[i]
			next = @nodes[i+1]
			ctxt.beginPath()
			ctxt.moveTo(cur.pos.x, cur.pos.y)
			ctxt.lineTo(next.pos.x,next.pos.y)
			ctxt.stroke()

	inView: (offset = {x:0, y:0}) ->
		true

# Exports
window.Rope = Rope
