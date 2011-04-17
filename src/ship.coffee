class Ship
	constructor: (ship) ->
		@id = ship.id
		@pos = ship.pos
		@dir = ship.dir
		@vel = ship.vel
		@firePower = ship.firePower

		@dead = ship.dead
		@exploding = ship.exploding
		@exploFrame = ship.exploFrame

		if @exploding
			if not explosions[@id]?
				@explode()
			@updateExplosion()

		@color = ship.color

	isExploding: () ->
		return @exploding

	isDead: () ->
		return @dead
	
	draw: (ctxt, offset) ->
		if @isDead()
			return
		else if @isExploding()
			@drawExplosion ctxt, offset
		else
			@drawShip ctxt, offset

	drawShip: (ctxt, offset = {x: 0, y: 0}) ->
		x = @pos.x - view.x + offset.x
		y = @pos.y - view.y + offset.y
		cos = Math.cos @dir
		sin = Math.sin @dir

		points = [[-7,10], [0,-10], [7,10], [0,6]]
		for i, p of points
			points[i] = [p[0]*cos - p[1]*sin, p[0]*sin + p[1]*cos]

		ctxt.strokeStyle = color @color
		ctxt.fillStyle = color @color, (@firePower-1)/maxPower
		ctxt.beginPath()
		ctxt.moveTo x+points[3][0], y+points[3][1]
		for i in [0..3]
			ctxt.lineTo x+points[i][0], y+points[i][1]
		ctxt.closePath()
		ctxt.stroke()
		ctxt.fill()

	explode: () ->
		@exploding = on
		explosions[@id] = []

		vel = Math.max @vel.x, @vel.y
		for i in [0..200]
			explosions[@id].push
				x: @pos.x
				y: @pos.y
				vx: .5*vel*(2*Math.random()-1)
				vy: .5*vel*(2*Math.random()-1)

	updateExplosion: () ->
		for b in explosions[@id]
			b.x += b.vx + (-1 + 2*Math.random())/1.5
			b.y += b.vy + (-1 + 2*Math.random())/1.5

	drawExplosion: (ctxt, offset = {x: 0, y: 0}) ->
		ox = -view.x + offset.x
		oy = -view.y + offset.y

		ctxt.fillStyle = color @color, (maxExploFrame-@exploFrame)/maxExploFrame
		for b in explosions[@id]
			ctxt.fillRect b.x+ox, b.y+oy, 4, 4
