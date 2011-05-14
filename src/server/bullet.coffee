ChangingObject = require('./changingObject').ChangingObject
server = require './server'
prefs = require './prefs'
utils = require '../utils'

class Bullet extends ChangingObject
	constructor: (@owner, @id) ->
		super()

		@watchChanges 'type'
		@watchChanges 'color'
		@watchChanges 'hitRadius'
		@watchChanges 'points'
		@watchChanges 'lastPoints'
		@watchChanges 'serverDelete'

		@type = 'bullet'

		xdir = 10*Math.sin(@owner.dir)
		ydir = -10*Math.cos(@owner.dir)

		@power = @owner.firePower
		@pos =
			x: @owner.pos.x + xdir
			y: @owner.pos.y + ydir
		@accel =
			x: @owner.vel.x + @power*xdir
			y: @owner.vel.y + @power*ydir

		@state = 'active'
		@hitRadius = prefs.bullet.hitRadius

		@color = @owner.color
		@points = [ [@pos.x, @pos.y] ]
		@lastPoints = [ [@pos.x, @pos.y] ]

	move: () ->
		return if @state isnt 'active'

		# Compute new position from acceleration and gravity of all planets.
		{x, y} = @pos
		{x: ax, y: ay} = @accel

		g = prefs.bullet.gravityPull
		for id, p of server.game.planets
			d = (p.pos.x-x)*(p.pos.x-x) + (p.pos.y-y)*(p.pos.y-y)
			d2 = g * p.force / (d * Math.sqrt(d))
			ax -= (x-p.pos.x) * d2
			ay -= (y-p.pos.y) * d2

		@pos.x = x + ax
		@pos.y = y + ay
		@accel.x = ax
		@accel.y = ay

		@points.push [@pos.x, @pos.y]
		@lastPoints = [ [@pos.x, @pos.y] ]

		# Warp the bullet around the map.
		{w, h} = prefs.server.mapSize
		@warp = off
		if @pos.x < 0
			@pos.x += w
			@warp = on
		if @pos.x > w
			@pos.x -= w
			@warp = on
		if @pos.y < 0
			@pos.y += h
			@warp = on
		if @pos.y > h
			@pos.y -= h
			@warp = on

		# Append the warped point again so that the line remains continuous.
		if @warp
			@points.push [@pos.x, @pos.y]
			@lastPoints.push [@pos.x, @pos.y]

	update: () ->
		switch @state
			# Seek and destroy.
			when 'active'
				@points.shift() if @points.length > prefs.bullet.tailLength

			# No points left, disappear.
			when 'dead'
				@serverDelete = yes

	tangible: ->
		@state is 'active'

	collidesWith: ({pos: {x,y}, hitRadius}) ->
		# Check collisions on the line between the two latest points.
		[Ax, Ay] = if @warp then @points[@points.length-3] else @points[@points.length-2]
		[Bx, By] = if @warp then @points[@points.length-2] else @points[@points.length-1]

		return utils.lineInterCircle(Ax,Ay, Bx,By, @hitRadius, x,y,hitRadius, prefs.bullet.checkWidth)?

exports.Bullet = Bullet
