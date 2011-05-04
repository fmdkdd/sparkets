ChangingObject = require './changingObject'
globals = require './server'
utils = require '../utils'

class Bullet extends ChangingObject.ChangingObject
	constructor: (@owner, @id) ->
		super()

		@watchChanges 'color'
		@watchChanges 'points'
		@watchChanges 'lastPoint'

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
		@points = [ [@pos.x, @pos.y] ]
		@lastPoint = [@pos.x, @pos.y]

	step: () ->
		return if @dead

		# Compute new position from acceleration and gravity of all planets.
		{x, y} = @pos
		{x: ax, y: ay} = @accel

		for p in globals.planets
			d = (p.pos.x-x)*(p.pos.x-x) + (p.pos.y-y)*(p.pos.y-y)
			d2 = 200 * p.force / (d * Math.sqrt(d))
			ax -= (x-p.pos.x) * d2
			ay -= (y-p.pos.y) * d2

		@pos.x = x + ax
		@pos.y = y + ay
		@accel.x = ax
		@accel.y = ay

		@points.push [@pos.x, @pos.y]
		@lastPoint = [@pos.x, @pos.y]

		# Warp the bullet around the map.
		warp = off
		if @pos.x < 0 then @pos.x += globals.map.w and warp = on
		if @pos.x > globals.map.w then @pos.x += -globals.map.w and warp = on
		if @pos.y < 0 then @pos.y += globals.map.h and warp = on
		if @pos.y > globals.map.h then @pos.y += -globals.map.h and warp = on

		# Append the warped point again so that the line remains continuous.
		@points.push [@pos.x, @pos.y] if warp

		@dead = @collides()

	collides : () ->
		@collidesWithPlanet()

	collidesWithPlanet : () ->
		{x, y} = @pos

		for p in globals.planets
			px = p.pos.x
			py = p.pos.y
			return true if utils.distance(px, py, x, y) < p.force

		return false

exports.Bullet = Bullet