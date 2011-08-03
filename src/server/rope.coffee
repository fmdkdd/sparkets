utils = require '../utils'
ChangingObject = require('./changingObject').ChangingObject

class Rope extends ChangingObject
	constructor: (@game, @id, @holder, @holdee, @ropeLength, @segments) ->
		super()

		# Send these properties to new players.
		@flagFullUpdate('type')
		@flagFullUpdate('color')
		@flagFullUpdate('serverDelete')
		@flagFullUpdate('chain')
		@flagFullUpdate('boundingRadius')
		@flagFullUpdate('hitBox') if @game.prefs.debug.sendHitBoxes

		@type = 'rope'
		@flagNextUpdate('type')

		# Take color of holder, holdee, or default black.
		@color = @holder.color or @holdee.color or 'black'

		@flagNextUpdate('color')

		# Nodes are the rope articulation points.
		@nodes = []
		@segmentLength = @ropeLength / @segments
		for i in [0...@segments-1]
			@nodes.push
				pos:
					x: @holder.pos.x + (i+1) * (@holdee.pos.x - @holder.pos.x) / @segments
					y: @holder.pos.y + (i+1) * (@holdee.pos.y - @holder.pos.y) / @segments
				vel:
					x: 0
					y: 0

		# The chain is used to send the position of each node to clients.
		@updateChain()

		# We need a position to insert in the grid. The object is
		# inserted in all cells overlapping with its bounding box.
		@pos =
			x: @nodes[0].pos.x
			y: @nodes[0].pos.y

		# Make sur all the rope is in the bounding box.
		@boundingRadius = (@nodes.map (a) =>
			utils.distance(@pos.x, @pos.y, a.pos.x, a.pos.y)).reduce (a,b) ->
				Math.max(a,b)

		@flagNextUpdate('boundingRadius')

		# Construct hit box with all node points.
		@hitBox =
			type: 'segments'
			points: []

		# The chain contains the positions of every node plus the 
		# positions of the two objects whereas the node is only
		# articulation points.
		for p in @chain
			@hitBox.points.push
				x: p.x
				y: p.y

		@flagNextUpdate('hitBox.points') if @game.prefs.debug.sendHitBoxes

	tangible: () ->
		yes

	move: (step) ->
		# Don't move if no object is attached.
		return if not @holder? or not @holdee?

		# Update each node position.
		for n in @nodes
			n.pos.x += n.vel.x
			n.pos.y += n.vel.y

			# Warp around the map.
			utils.warp(n.pos, @game.prefs.mapSize)

		# Build a chain starting from the first object, containing all
		# nodes and ending with the second object.
		rope = [@holder].concat(@nodes).concat([@holdee])

		# Enforce the distance constraints.
		for i in [0...rope.length-1]
			cur = rope[i]
			next = rope[i+1]
			next.vel = {x:0,y:0}

			# XXX: is this really necessary?
			ghost = @game.closestGhost(cur.pos, next.pos)

			dist = utils.distance(cur.pos.x, cur.pos.y, ghost.x, ghost.y)
			if dist > @segmentLength
				ratio = (dist - @segmentLength) / dist
				next.vel.x += ratio * (cur.pos.x - ghost.x)
				next.vel.y += ratio * (cur.pos.y - ghost.y)

		# Update bounding box and hitbox
		@pos =
			x: @nodes[0].pos.x
			y: @nodes[0].pos.y

		# Should contain all the nodes.
		#
		# FIXME: max distance from first point is erroneous. I think
		# rope length is a correct upper bound. We should also center
		# the bounding box, since it's currently useless if the first
		# point is also the farthest to the right and down.
		@boundingRadius = (@nodes.map (a) =>
			utils.distance(@pos.x, @pos.y, a.pos.x, a.pos.y)).reduce (a,b) ->
				Math.max(a,b)

	update: (step) ->
		# Don't send chain if no object is attached.
		return if not @holder? or not @holdee?

		@updateChain()

		# The hitbox is based on the chain and must be updated in order.
		@updateHitBox()

	updateChain: () ->
		# Prepare the chain which will be sent to the client.
		rope = [@holder].concat(@nodes).concat([@holdee])

		@chain = []
		for n in rope
			@chain.push n.pos

		@flagNextUpdate('chain')

	updateHitBox: () ->
		for i in [0...@chain.length]
			@hitBox.points[i].x = @chain[i].x
			@hitBox.points[i].y = @chain[i].y

		@flagNextUpdate('hitBox.points') if @game.prefs.debug.sendHitBoxes

	detach: () ->
		@holder = null
		@holdee = null

		@serverDelete = yes

		@flagNextUpdate('serverDelete')

		@game.events.push
			type: 'rope exploded'
			id: @id

exports.Rope = Rope
