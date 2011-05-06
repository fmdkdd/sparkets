class Ship
	constructor: (ship) ->
		@update(ship)

		@explosionBits = null

	update: (ship) ->
		for field, val of ship
			@[field] = val

		# Start the explosion animation if the ship just exploded.
		if @exploding
			@explode() if not @explosionBits?
			@stepExplosion()
		# Reset the explosion bits if the ship respawned.
		else if not @exploding and @explosionBits?
			delete @explosionBits

	isExploding: () ->
		return @exploding

	isDead: () ->
		return @dead

	draw: (ctxt, offset) ->
		if @dead
			return
		else if @exploding
			@drawExplosion(ctxt, offset)
		else
			@drawShip(ctxt, offset)

	drawShip: (ctxt, offset = {x: 0, y: 0}) ->
		x = @pos.x - view.x + offset.x
		y = @pos.y - view.y + offset.y
		cos = Math.cos @dir
		sin = Math.sin @dir

		# Draw hull.

		points = [[-7,10], [0,-10], [7,10], [0,6]]
		for i, p of points
			points[i] = [p[0]*cos - p[1]*sin, p[0]*sin + p[1]*cos]

		ctxt.strokeStyle = color @color
		ctxt.fillStyle = color @color, (@firePower-minPower)/(maxPower-minPower)
		ctxt.lineWidth = 4
		ctxt.beginPath()
		ctxt.moveTo x+points[3][0], y+points[3][1]
		for i in [0..3]
			ctxt.lineTo x+points[i][0], y+points[i][1]
		ctxt.closePath()
		ctxt.stroke()
		ctxt.fill()

		# Draw engine fire.
		if @thrust
			ctxt.lineWidth = 2
			enginePoints = [ [0,18], [-5,8], [5,8], [0,18] ]
			for i, p of enginePoints
				enginePoints[i] = [p[0]*cos - p[1]*sin, p[0]*sin + p[1]*cos]
			ctxt.beginPath()
			ctxt.moveTo x+enginePoints[0][0], y+enginePoints[0][1]
			for p in enginePoints
				ctxt.lineTo x+p[0], y+p[1]
			ctxt.stroke()
			ctxt.lineWidth = 4

	explode: () ->
		@explosionBits = []

		vel = Math.max @vel.x, @vel.y
		for i in [0..200]
			particle =
				x: @pos.x
				y: @pos.y
				vx: .5*vel*(2*Math.random()-1)
				vy: .5*vel*(2*Math.random()-1)
				size: Math.random() * 10
			angle = Math.atan2(particle.vy, particle.vx)
			particle.vx *= Math.abs(Math.cos angle)
			particle.vy *= Math.abs(Math.sin angle)
			@explosionBits.push particle

	stepExplosion: () ->
		for b in @explosionBits
			b.x += b.vx + (-1 + 2*Math.random())/1.5
			b.y += b.vy + (-1 + 2*Math.random())/1.5

	drawExplosion: (ctxt, offset = {x: 0, y: 0}) ->
		ox = -view.x + offset.x
		oy = -view.y + offset.y

		ctxt.fillStyle = color @color, (maxExploFrame-@exploFrame)/maxExploFrame
		for b in @explosionBits
			ctxt.fillRect b.x+ox, b.y+oy, b.size, b.size

	drawOnRadar: (ctxt) ->
		localShip = ships[id]

		# Select the closest ship among the real one and its ghosts.
		bestDistance = Infinity
		for j in [-1..1]
			for k in [-1..1]
				x = @pos.x + j * map.w
				y = @pos.y + k * map.h
				d = distance(localShip.pos.x, localShip.pos.y, x, y)

				if d < bestDistance
					bestDistance = d
					bestPos = {x, y}

		dx = bestPos.x - localShip.pos.x
		dy = bestPos.y - localShip.pos.y

		# Draw the radar if the ship is outside of the screen bounds.
		if Math.abs(dx) > screen.w/2 or Math.abs(dy) > screen.h/2

			margin = 20
			rx = Math.max -screen.w/2 + margin, dx
			rx = Math.min screen.w/2 - margin, rx
			ry = Math.max -screen.h/2 + margin, dy
			ry = Math.min screen.h/2 - margin, ry

			# Choose on which ship we should base the animation. If the two
			# of them are exploding, focus on the first to die.
			if @isExploding() and localShip.isExploding()
				dying = if @exploFrame > localShip.exploFrame then @ else localShip
			else if @isExploding()
				dying = @
			else if localShip.isExploding()
				dying = localShip

			radius = 10
			alpha = 1

			if dying?
				animRatio = dying.exploFrame / maxExploFrame
				radius -= animRatio * 10
				alpha -= animRatio

			ctxt.fillStyle = color(@color, alpha)
			ctxt.beginPath()
			ctxt.arc(screen.w/2 + rx, screen.h/2 + ry, radius, 0, 2*Math.PI, false)
			ctxt.fill()

		return true
