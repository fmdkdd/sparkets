class Ship
	constructor: (ship) ->
		@pos = ship.pos
		@dir = ship.dir
		@vel = ship.vel
		@firePower = ship.firePower

		@dead = ship.dead
		@exploBits = ship.exploBits
		@exploFrame = ship.exploFrame

		@color = ship.color

	isDead: () ->
		return @dead or @exploBits?
	
	draw: (ctxt, offset) ->
		if @dead
			return
		else if @exploBits?
			@drawExplosion(ctxt, offset)
		else
			@drawShip(ctxt, offset)

	drawShip: (ctxt, offset = x:0, y:0) ->
		x = @pos.x - view.x + offset.x
		y = @pos.y - view.y + offset.y
		
		cos = Math.cos(@dir)
		sin = Math.sin(@dir)

		points = [[-7,10] [0,-10] [7,10] [0,6]]
		for p in points
			p = x: p[0]*cos - p[1]*sin, y: p[0]*sin + p[1]*cos

		ctxt.strokeStyle = color(@color)
		ctxt.fillStyle = color(@color, (@firePower-1)/maxPower)
		ctxt.beginPath()
		ctxt.moveTo(x+points[3][0], y+points[3][1])
		for p in points
			ctxt.lineTo(x+points[p][0], y+points[p][1])
		ctxt.closePath()
		ctxt.stroke()
		ctxt.fill()

	explode: () ->
		@exploBits = []
		vel = Math.max(@vel.x, @vel.y)

		for i in [0..200]
			@exploBits.push(
				x: @pos.x,
				y: @pos.y,
				vx : .5*vel * (2*Math.random() -1),
				vy : .5*vel * (2*Math.random() -1)
			)
		@exploFrame = 0

	drawExplosion: (ctxt, offset = x:0, y:0) ->
		ox = -view.x + offset.x
		oy = -view.y + offset.y

		ctxt.fillStyle = color(@color, (maxExploFrame-@exploFrame)/maxExploFrame)
		for b in @exploBits
			ctxt.fillRect(b.x + ox, b.y + oy, 4, 4)
