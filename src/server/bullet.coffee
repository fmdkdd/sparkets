class Bullet
	constructor: (@owner) ->
		xdir = 10*Math.sin(@owner.dir)
		ydir = -10*Math.cos(@owner.dir)

		@power = @owner.firePower
		@pos =
			x: @owner.pos.x + xdir
			y: @owner.pos.y + ydir
		@accel =
			x: @owner.vel.x + @power*xdir
			y: @owner.vel.y + @power*ydir
		@dead = false

		@color = owner.color
		@points = [[@pos.x, @pos.y]]

	step: () ->
		return if @dead

		# Compute new position from acceleration and gravity of all planets.
		x = @pos.x
		y = @pos.y
		ax = @accel.x
		ay = @accel.y

		for p in planets
			d = (p.pos.x-x)*(p.pos.x-x) + (p.pos.y-y)*(p.pos.y-y)
			d2 = 200 * p.force / (d * Math.sqrt(d))
			ax -= (x-p.pos.x) * d2
			ay -= (y-p.pos.y) * d2

		@pos.x = x + ax
		@pos.y = y + ay
		@accel.x = ax
		@accel.y = ay

		@points.push [@pos.x, @pos.y]

		# Warp the bullet around the map.
		warp = off
		if @pos.x < 0 then @pos.x += map.w and warp = on
		if @pos.x > map.w then @pos.x += -map.w and warp = on
		if @pos.y < 0 then @pos.y += map.h and warp = on
		if @pos.y > map.h then @pos.y += -map.h and warp = on

		# Append the warped point again so that the line remains continuous.
		@points.push [@pos.x, @pos.y] if warp

		@dead = @collides()

	collides : () ->
		@collidesWithPlanet()

	collidesWithPlanet : () ->
		x = @pos.x
		y = @pos.y

		for p in planets
			px = p.pos.x
			py = p.pos.y
			return true if distance(px, py, x, y) < p.force

		return false
