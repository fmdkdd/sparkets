ChangingObject = require './changingObject'
globals = require './server'
prefs = require './prefs'
utils = require '../utils'

class Bullet extends ChangingObject.ChangingObject
	constructor: (@owner, @id) ->
		super()

		@watchChanges 'type'
		@watchChanges 'color'
		@watchChanges 'hitRadius'
		@watchChanges 'points'
		@watchChanges 'lastPoint'
		@watchChanges 'tailTrim'

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
		@collisions = []

		@color = owner.color
		@points = [ [@pos.x, @pos.y] ]
		@lastPoint = [@pos.x, @pos.y]

	move: () ->
		return if @state isnt 'active'

		# Compute new position from acceleration and gravity of all planets.
		{x, y} = @pos
		{x: ax, y: ay} = @accel

		g = prefs.bullet.gravityPull
		for id, p of globals.planets
			d = (p.pos.x-x)*(p.pos.x-x) + (p.pos.y-y)*(p.pos.y-y)
			d2 = g * p.force / (d * Math.sqrt(d))
			ax -= (x-p.pos.x) * d2
			ay -= (y-p.pos.y) * d2

		@pos.x = x + ax
		@pos.y = y + ay
		@accel.x = ax
		@accel.y = ay

		@points.push [@pos.x, @pos.y]
		@lastPoint = [@pos.x, @pos.y]

		# Warp the bullet around the map.
		{w, h} = prefs.server.mapSize
		warp = off
		if @pos.x < 0
			@pos.x += w
			warp = on
		if @pos.x > w
			@pos.x -= w
			warp = on
		if @pos.y < 0
			@pos.y += h
			warp = on
		if @pos.y > h
			@pos.y -= h
			warp = on

		# Append the warped point again so that the line remains continuous.
		@points.push [@pos.x, @pos.y] if warp

	update: () ->
		switch @state
			# Seek and destroy.
			when 'active'
				@state = 'dead' if @collidedWith 'ship', 'planet'

			# No points left, disappear.
			when 'dead'
				@tailTrim = yes
				@deleteMe = yes

	collidesWith: ({pos: {x,y}, hitRadius}) ->
		@state is 'active' and utils.distance(@pos.x, @pos.y, x, y) < @hitRadius + hitRadius

exports.Bullet = Bullet