class Ship
	constructor: (ship) ->
		@serverUpdate(ship)

		@explosionBits = null

		@engineAnimFor = null
		@engineAnimDelay = 200

	serverUpdate: (ship) ->
		thrust_old = @thrust

		for field, val of ship
			@[field] = val

		# Start the engine fade-in/out in the ship just started/stopped thrusting.
		if @thrust isnt thrust_old
			@engineAnimFor = @engineAnimDelay

		# Start the explosion animation if the ship just exploded.
		if @exploding
			@explode() if not @explosionBits?
			@stepExplosion()
		# Reset the explosion bits if the ship respawned.
		else if not @exploding and @explosionBits?
			delete @explosionBits

		# Start the boost animation if the ship just boosted.
		if @boost > 1 and not @ghosts?
			@ghosts = []
		else if @boost <= 1 and @ghosts?
			delete @ghosts

	update: () ->

		# Update the engine animation countdown.
		if @engineAnimFor?
			@engineAnimFor -= window.sinceLastUpdate
			@engineAnimFor = null if @engineAnimFor <= 0

		# Update the ghosts trail.
		if @ghosts and (@ghosts.length is 0 or now-@ghosts[@ghosts.length-1].t > 0)
			@ghosts.push
				x: @pos.x
				y: @pos.y
				dir: @dir
				t: now
			@ghosts.shift() if @ghosts.length > 5

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
		x = @pos.x + offset.x
		y = @pos.y + offset.y

		# Check if ship is in view before drawing.
		if not window.inView(x+10, y+10) and
				not window.inView(x+10, y-10) and
				not window.inView(x-10, y+10) and
				not window.inView(x-10, y-10)
			return
		x -= window.view.x
		y -= window.view.y

		cos = Math.cos @dir
		sin = Math.sin @dir

		# Draw hull.

		if window.showHitCircles
			ctxt.strokeStyle = 'red'
			ctxt.lineWidth = 1
			strokeCircle(ctxt, x, y, @hitRadius)

		if @cannonHeat > 0
			fillAlpha = @cannonHeat/window.cannonCooldown
		else if @firePower > 0
			fillAlpha = (@firePower-window.minPower)/(window.maxPower-window.minPower)

		@drawShipModel(ctxt, x, y, @dir, 1, fillAlpha)

		# Draw ghosts trail.
		if @ghosts?
			for i of @ghosts
				@drawShipModel(ctxt,
						@ghosts[i].x+offset.x-window.view.x,
						@ghosts[i].y+offset.y-window.view.y,
						@ghosts[i].dir,
						0.1,
						0)

		# Draw engine fire.
		if @thrust or @engineAnimFor?

			alpha = 1
			if @engineAnimFor? and @thrust
				alpha = 1-@engineAnimFor/@engineAnimDelay
			else if @engineAnimFor?
				alpha = @engineAnimFor/@engineAnimDelay

			ctxt.strokeStyle = color(@color, alpha)
			enginePoints = [[-8,-5], [-18,0], [-8,5]]
			ctxt.lineWidth = 2
			ctxt.save()
			ctxt.translate(x, y)
			ctxt.rotate(@dir)
			ctxt.scale(1, Math.max(0.85,alpha))
			if @boost > 1
				boostScale = @boost-1
				ctxt.scale(1 + .15*boostScale, 1 + .3*boostScale)
			ctxt.beginPath()
			for p in enginePoints
				ctxt.lineTo(p[0], p[1])
			ctxt.stroke()
			ctxt.restore()

		# Draw the player's name.
		if 	@name?  and @ isnt window.localShip and
				(displayNames is on or
				window.localShip.isExploding() or window.localShip.isDead())
			ctxt.fillStyle = '#666'
			ctxt.font = '15px sans'
			ctxt.fillText(@name, x - ctxt.measureText(@name).width/2, y - 25)

	drawShipModel: (ctxt, x, y, dir, strokeAlpha, fillAlpha) ->
		points = [[-10,-7], [10,0], [-10,7], [-6,0]]

		ctxt.fillStyle = color(@color, fillAlpha)
		ctxt.strokeStyle = color(@color, strokeAlpha)
		ctxt.lineWidth = 4

		ctxt.save()
		ctxt.translate(x, y)
		ctxt.rotate(@dir)
		ctxt.beginPath()
		for p in points
			ctxt.lineTo(p[0], p[1])
		ctxt.closePath()
		ctxt.stroke()
		ctxt.fill()
		ctxt.restore()

	explode: () ->
		@explosionBits = []

		# Initial particle speed is derived from ship speed at death
		# and killing bullet speed.
		[vx, vy] = [@vel.x, @vel.y]
		nvel = Math.sqrt(vx*vx + vy*vy)

		if @killingAccel?
			[ax, ay] = [@killingAccel.x, @killingAccel.y]
			nacc = Math.sqrt(ax*ax + ay*ay)
			speed = Math.max nvel, .5*nacc
		else
			speed = nvel

		# Ensure decent fireworks.
		speed = Math.max(speed, 3)

		# Create explosion particles.
		for i in [0..200]
			particle =
				x: @pos.x
				y: @pos.y
				vx: .35* speed *(2*Math.random()-1)
				vy: .35* speed *(2*Math.random()-1)
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
		ox = -window.view.x + offset.x
		oy = -window.view.y + offset.y

		ctxt.fillStyle = color(@color, (window.maxExploFrame-@exploFrame)/window.maxExploFrame)
		for b in @explosionBits
			if window.inView(b.x+offset.x, b.y+offset.y)
				ctxt.fillRect b.x+ox, b.y+oy, b.size, b.size

	drawOnRadar: (ctxt) ->
		# Select the closest ship among the real one and its ghosts.
		bestDistance = Infinity
		for j in [-1..1]
			for k in [-1..1]
				x = @pos.x + j * map.w
				y = @pos.y + k * map.h
				d = distance(window.localShip.pos.x, window.localShip.pos.y, x, y)

				if d < bestDistance
					bestDistance = d
					bestPos = {x, y}

		dx = bestPos.x - window.localShip.pos.x
		dy = bestPos.y - window.localShip.pos.y

		# Draw the radar if the ship is outside of the screen bounds.
		if Math.abs(dx) > window.screen.w/2 or Math.abs(dy) > window.screen.h/2

			margin = 20
			rx = Math.max -window.screen.w/2 + margin, dx
			rx = Math.min window.screen.w/2 - margin, rx
			ry = Math.max -window.screen.h/2 + margin, dy
			ry = Math.min window.screen.h/2 - margin, ry

			radius = 10
			alpha = 1

			if @isExploding()
				animRatio = @exploFrame / window.maxExploFrame
				radius -= animRatio * 10
				alpha -= animRatio

			ctxt.fillStyle = color(@color, alpha)
			ctxt.beginPath()
			ctxt.arc(window.screen.w/2 + rx, window.screen.h/2 + ry, radius, 0, 2*Math.PI, false)
			ctxt.fill()

		return true

# Exports
window.Ship = Ship
