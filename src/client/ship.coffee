class Ship
	constructor: (ship) ->
		@serverUpdate(ship)

		@engineAnimFor = null
		@engineAnimDelay = 200

	serverUpdate: (ship) ->
		thrust_old = @thrust
		exploding_old = @exploding

		for field, val of ship
			@[field] = val

		# Start the engine fade-in/out in the ship just started/stopped thrusting.
		if @thrust isnt thrust_old
			@engineAnimFor = @engineAnimDelay

		# Launch an explosion animation if the ship just exploded.
		if @exploding and exploding_old isnt @exploding
			@explode()

		# Start the boost animation if the ship just boosted.
		###
		if @boost > 1 and not @ghosts?
			@ghosts = []
		###

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

	inView: (offset = {x:0, y:0}) ->
		window.boxInView(@pos.x + offset.x,
			@pos.y + offset.y, 10)

	drawHitbox: (ctxt) ->
		ctxt.strokeStyle = 'red'
		ctxt.lineWidth = 1
		strokeCircle(ctxt, @pos.x, @pos.y, @hitRadius)

	draw: (ctxt, offset) ->
		return if @exploding or @dead

		# Draw the basic model.
		ctxt.save()
		ctxt.translate(@pos.x, @pos.y)
		ctxt.rotate(@dir)
		@drawModel(ctxt, color(@color))
		ctxt.restore()

		# Color the hull depending on the cannon heat.
		if @cannonHeat > 0
			fillAlpha = @cannonHeat/window.cannonCooldown
		else if @firePower > 0
			fillAlpha = (@firePower-window.minPower)/(window.maxPower-window.minPower)

		points = [[-10,-7], [10,0], [-10,7], [-6,0]]
		ctxt.save()
		ctxt.translate(@pos.x, @pos.y)
		ctxt.rotate(@dir)
		ctxt.fillStyle = color(@color, fillAlpha)
		ctxt.beginPath()
		for p in points
			ctxt.lineTo(p[0], p[1])
		ctxt.closePath()
		ctxt.fill()
		ctxt.restore()

		# Draw engine fire.
		if @thrust or @engineAnimFor?
			alpha = 1
			if @engineAnimFor? and @thrust
				alpha = 1-@engineAnimFor/@engineAnimDelay
			else if @engineAnimFor?
				alpha = @engineAnimFor/@engineAnimDelay

			ctxt.strokeStyle = color(@color, alpha)
			points = [[-8,-5], [-18,0], [-8,5]]
			ctxt.lineWidth = 2
			ctxt.save()
			ctxt.translate(@pos.x, @pos.y)
			ctxt.rotate(@dir)
			ctxt.scale(1, Math.max(0.85,alpha))
			if @boost > 1
				boostScale = @boost-1
				ctxt.scale(1 + .15*boostScale, 1 + .3*boostScale)
			ctxt.beginPath()
			for p in points
				ctxt.lineTo(p[0], p[1])
			ctxt.stroke()
			ctxt.restore()

		# Draw the player's name.
		if 	@name?  and @ isnt window.localShip and
				(displayNames is on or
				window.localShip.exploding or window.localShip.dead)
			ctxt.fillStyle = '#666'
			ctxt.font = '15px sans'
			ctxt.fillText(@name, @pos.x - ctxt.measureText(@name).width/2, @pos.y - 25)

	drawModel: (ctxt, col) ->
		points = [[-10,-7], [10,0], [-10,7], [-6,0]]

		ctxt.strokeStyle = col
		ctxt.lineJoin = 'round'
		ctxt.lineWidth = 4

		ctxt.beginPath()
		for p in points
			ctxt.lineTo(p[0], p[1])
		ctxt.closePath()
		ctxt.stroke()

	explode: () ->
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

		window.effects.push new ExplosionEffect(@pos, @color, 200, 10, speed)

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
		if Math.abs(dx) > window.canvasSize.w/2 or Math.abs(dy) > window.canvasSize.h/2

			margin = 20
			rx = Math.max -window.canvasSize.w/2 + margin, dx
			rx = Math.min window.canvasSize.w/2 - margin, rx
			ry = Math.max -window.canvasSize.h/2 + margin, dy
			ry = Math.min window.canvasSize.h/2 - margin, ry

			radius = 10
			alpha = 1

			if @exploding
				animRatio = @exploFrame / window.maxExploFrame
				radius -= animRatio * 10
				alpha -= animRatio

			ctxt.fillStyle = color(@color, alpha)
			ctxt.beginPath()
			ctxt.arc(window.canvasSize.w/2 + rx, window.canvasSize.h/2 + ry, radius, 0, 2*Math.PI, false)
			ctxt.fill()

		return true

# Exports
window.Ship = Ship
