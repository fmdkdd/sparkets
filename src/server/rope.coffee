utils = require '../utils'
ChangingObject = require('./changingObject').ChangingObject

class Rope extends ChangingObject
	constructor: (@game, @id, @object1, @object2, @ropeLength, @segments) ->
		super()

		@watchChanges 'type'
		@watchChanges 'hitRadius'
		@watchChanges 'color'
		@watchChanges 'serverDelete'
		@watchChanges 'chain'
		
		@type = 'rope'
		@hitRadius = 0

		if @object1.color?
			@color = @object1.color
		else if @object2.color?
			@color = @object2.color
		else
			@color = 'black'

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

	tangible: () ->
		no

	collidesWith: ({pos: {x,y}, hitRadius}, offset = {x:0, y:0}) ->
		x += offset.x
		y += offset.y
		utils.distance(@pos.x, @pos.y, x, y) < @hitRadius + hitRadius

	move: () ->
		return if not @object1? or not @object2?

		# Update each node position.
		for n in @nodes
			n.pos.x += n.vel.x
			n.pos.y += n.vel.y

			# Warp around the map.
			{w, h} = @game.prefs.mapSize
			n.pos.x = if n.pos.x < 0 then w else n.pos.x
			n.pos.x = if n.pos.x > w then 0 else n.pos.x
			n.pos.y = if n.pos.y < 0 then h else n.pos.y
			n.pos.y = if n.pos.y > h then 0 else n.pos.y

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

	update: () ->

	detach: () ->
		@object1 = null
		@object2 = null

		@serverDelete = yes

exports.Rope = Rope
