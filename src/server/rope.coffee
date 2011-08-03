utils = require '../utils'
ChangingObject = require('./changingObject').ChangingObject

class Rope extends ChangingObject
	constructor: (@game, @id, @holder, @holdee, @ropeLength, @segments) ->
		super()

		# Send these properties to new players.
		@flagFullUpdate('type')
		@flagFullUpdate('color')
		@flagFullUpdate('serverDelete')
		@flagFullUpdate('clientChain')
		@flagFullUpdate('boundingRadius')
		@flagFullUpdate('hitBox') if @game.prefs.debug.sendHitBoxes

		@type = 'rope'
		@flagNextUpdate('type')

		# Take color of holder, holdee, or default black.
		@color = @holder.color or @holdee.color or 'black'
		@flagNextUpdate('color')

		# The chain contains each object at its ends plus the articulation
		# points inbetween them.
		@segmentLength = @ropeLength / @segments
		seg =
			x: (@holdee.pos.x - @holder.pos.x) / @segments
			y: (@holdee.pos.y - @holder.pos.y) / @segments

		@chain = [@holder]
		for i in [0...@segments-1]
			@chain.push
				pos:
					x: @holder.pos.x + (i+1) * seg.x
					y: @holder.pos.y + (i+1) * seg.y
				vel:
					x: 0
					y: 0
		@chain.push @holdee

		# The client chain only contains positions from the chain.
		@updateClientChain()

		# We need a position to insert in the grid. The object is
		# inserted in all cells overlapping with its bounding box.
		@pos =
			x: @chain[0].pos.x
			y: @chain[0].pos.y

		# Make sur all the rope is in the bounding box.
		@boundingRadius = (@chain.map (a) =>
			utils.distance(@pos.x, @pos.y, a.pos.x, a.pos.y)).reduce (a,b) ->
				Math.max(a,b)

		@flagNextUpdate('boundingRadius')

		# Construct hit box with all chain positions.
		@hitBox =
			type: 'segments'
			points: []

		for n in @chain
			@hitBox.points.push
				x: n.pos.x
				y: n.pos.y

		@flagNextUpdate('hitBox.points') if @game.prefs.debug.sendHitBoxes

	tangible: () ->
		yes

	move: (step) ->
		# Don't move if no object is attached.
		return if not @holder? or not @holdee?

		# Update each articulation point position.
		for i in [1...@chain.length-1]
			n = @chain[i]
			n.pos.x += n.vel.x
			n.pos.y += n.vel.y

			# Warp around the map.
			utils.warp(n.pos, @game.prefs.mapSize)

		# Enforce the distance constraints.
		# Each node must pull the following one.
		for i in [0...@chain.length-1]
			cur = @chain[i]
			next = @chain[i+1]
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
			x: @chain[0].pos.x
			y: @chain[0].pos.y

		# Should contain all the nodes.
		#
		# FIXME: max distance from first point is erroneous. I think
		# rope length is a correct upper bound. We should also center
		# the bounding box, since it's currently useless if the first
		# point is also the farthest to the right and down.
		@boundingRadius = (@chain.map (a) =>
			utils.distance(@pos.x, @pos.y, a.pos.x, a.pos.y)).reduce (a,b) ->
				Math.max(a,b)

		@updateHitBox()

	update: (step) ->
		# Don't send chain if no object is attached.
		return if not @holder? or not @holdee?

		@updateClientChain()

	updateClientChain: () ->
		@clientChain = []

		for n in @chain
			@clientChain.push n.pos

		@flagNextUpdate('clientChain')

	updateHitBox: () ->
		for i in [0...@chain.length]
			@hitBox.points[i].x = @chain[i].pos.x
			@hitBox.points[i].y = @chain[i].pos.y

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
