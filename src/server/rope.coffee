utils = require '../utils'
ChangingObject = require('./changingObject').ChangingObject

class Rope extends ChangingObject
	constructor: (@game, @id, @object1, @object2, @ropeLength, @segments) ->
		super()

		@watchChanges 'type'
		@watchChanges 'color'
		@watchChanges 'serverDelete'
		@watchChanges 'chain'
		@watchChanges 'boundingRadius'
		@watchChanges 'hitBox' if @game.prefs.debug.sendHitBoxes

		@type = 'rope'

		@color = @object1.color or @object2.color or 'black'

		@chain = []
		@nodes = []
		@segmentLength = @ropeLength / @segments
		for i in [0...@segments-1]
			@nodes.push
				pos:
					x: @object1.pos.x + (i+1) * (@object2.pos.x - @object1.pos.x) / @segments
					y: @object1.pos.y + (i+1) * (@object2.pos.y - @object1.pos.y) / @segments
				vel:
					x: 0
					y: 0

		# We need a position to insert in the grid. The object is
		# inserted in all cells overlapping with its bounding box.
		@pos =
			x: @nodes[0].pos.x
			y: @nodes[0].pos.y

		# Make sur all the rope is in the bounding box.
		@boundingRadius = (@nodes.map (a) =>
			utils.distance(@pos.x, @pos.y, a.pos.x, a.pos.y)).reduce (a,b) ->
				Math.max(a,b)

		@hitBox =
			type: 'segments'
			points: []

		for n in @nodes
			@hitBox.points.push
				x: n.pos.x
				y: n.pos.y

		true

	tangible: () ->
		yes

	move: () ->
		return if not @object1? or not @object2?

		# Update each node position.
		for n in @nodes
			n.pos.x += n.vel.x
			n.pos.y += n.vel.y

			# Warp around the map.
			s = @game.prefs.mapSize
			n.pos.x = if n.pos.x < 0 then s else n.pos.x
			n.pos.x = if n.pos.x > s then 0 else n.pos.x
			n.pos.y = if n.pos.y < 0 then s else n.pos.y
			n.pos.y = if n.pos.y > s then 0 else n.pos.y

		# Build a chain starting from the first object, containing all
		# nodes and ending with the second object.
		rope = [@object1].concat(@nodes).concat([@object2])

		# Enforce the distance constraints.
		for i in [0...rope.length-1]
			cur = rope[i]
			next = rope[i+1]
			next.vel = {x:0,y:0}
			ghost = @game.closestGhost(cur.pos, next.pos)
			dist = utils.distance(cur.pos.x, cur.pos.y, ghost.x, ghost.y)
			if dist > @segmentLength
				ratio = (dist - @segmentLength) / dist
				next.vel.x += ratio * (cur.pos.x - ghost.x)
				next.vel.y += ratio * (cur.pos.y - ghost.y)

			#next.vel.x *= @game.prefs.ship.frictionDecay
			#next.vel.y *= @game.prefs.ship.frictionDecay

		# Prepare the chain which will be sent to the client.
		@chain = []
		for n in rope
			@chain.push n.pos
		@changed 'chain'

		# Update bounding box and hitbox
		@pos =
			x: @nodes[0].pos.x
			y: @nodes[0].pos.y

		@boundingRadius = (@nodes.map (a) =>
			utils.distance(@pos.x, @pos.y, a.pos.x, a.pos.y)).reduce (a,b) ->
				Math.max(a,b)

		for i in [0...@nodes.length]
			@hitBox.points[i].x = @nodes[i].pos.x
			@hitBox.points[i].y = @nodes[i].pos.y
		@changed 'hitBox'

	update: () ->

	detach: () ->
		@object1 = null
		@object2 = null

		@serverDelete = yes

		@game.events.push
			type: 'rope exploded'
			id: @id

exports.Rope = Rope
