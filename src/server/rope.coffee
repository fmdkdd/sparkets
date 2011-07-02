prefs = require './prefs'
utils = require '../utils'
ChangingObject = require('./changingObject').ChangingObject

class Rope extends ChangingObject
	constructor: (@game, @id, @object1, @object2, @ropeLength, @segments) ->
		super()

		@watchChanges 'type'
		@watchChanges 'hitRadius'
		@watchChanges 'color'
		@watchChanges 'serverDelete'
		@watchChanges 'nodes'
		@watchChanges 'object1Id'
		@watchChanges 'object2Id'

		@type = 'rope'
		@hitRadius = 0

		@nodes = []
		@segmentLength = @ropeLength / @segments
		for i in [0...@segments-1]
			@nodes.push
				pos:
					x: @object1.pos.x + (i+1) * (@object2.pos.x - @object1.pos.x) / @segments
					y: @object1.pos.y + (i+1) * (@object2.pos.y - @object1.pos.y) / @segments

		@object1Id = @object1.id
		@object2Id = @object2.id

	tangible: () ->
		no

	collidesWith: ({pos: {x,y}, hitRadius}, offset = {x:0, y:0}) ->
		x += offset.x
		y += offset.y
		utils.distance(@pos.x, @pos.y, x, y) < @hitRadius + hitRadius

	move: () ->
		# Build a chain starting from the first object, containing all
		# nodes and ending with the second object.
		chain = [@object1].concat(@nodes).concat([@object2])

		# Enforce the distance constraints.
		for i in [0...chain.length-1]
			cur = chain[i]
			next = chain[i+1]

			ghost = @game.closestGhost(cur.pos, next.pos)
			dist = utils.distance(cur.pos.x, cur.pos.y, ghost.x, ghost.y)
			diff = dist - @segmentLength
			if diff > 0
				ratio = diff / dist
				next.pos.x += ratio * (cur.pos.x - ghost.x)
				next.pos.y += ratio * (cur.pos.y - ghost.y)

				# Warp around the map.
				{w, h} = prefs.server.mapSize
				cur.pos.x = if cur.pos.x < 0 then w else cur.pos.x
				cur.pos.x = if cur.pos.x > w then 0 else cur.pos.x
				cur.pos.y = if cur.pos.y < 0 then h else cur.pos.y
				cur.pos.y = if cur.pos.y > h then 0 else cur.pos.y

		# Notify that the dragged object position has changed.
		chain[chain.length-1].changed 'pos'
		chain[chain.length-1].warp()

		@changed 'nodes'

	update: () ->
		true

exports.Rope = Rope
