class Ship
	constructor: (@client, ship) ->
		@serverUpdate(ship)

		@engineAnimFor = null
		@engineAnimDelay = 200

	serverUpdate: (ship) ->
		thrust_old = @thrust
		boost_old = @boost
		state_old = @state

		for field, val of ship
			@[field] = val

		# Start the engine fade-in/out in the ship just started/stopped thrusting.
		if @thrust isnt thrust_old
			@engineAnimFor = @engineAnimDelay

		# Launch an explosion animation if the ship just exploded.
		if @state is 'exploding' and state_old is 'alive'
			@explode()

		# Start the boost animation if the ship just boosted.
		if boost_old < @boost
			@client.effects.push new BoostEffect(@client, @, 1, 3000)

	update: () ->
		# Update the engine animation countdown.
		if @engineAnimFor?
			@engineAnimFor -= @client.sinceLastUpdate
			@engineAnimFor = null if @engineAnimFor <= 0

	inView: (offset = {x:0, y:0}) ->
		@client.boxInView(@pos.x + offset.x, @pos.y + offset.y, 10)

	drawHitbox: (ctxt) ->
		ctxt.strokeStyle = 'red'
		ctxt.lineWidth = 1
		strokeCircle(ctxt, @pos.x, @pos.y, @hitRadius)

	draw: (ctxt, offset) ->
		return if @state is 'exploding' or @state is 'dead'

		# Blink when the ship just spawned.
		return if @state is 'spawned' and @client.now % 200 < 100

		# Draw the basic model.
		ctxt.save()
		ctxt.translate(@pos.x, @pos.y)
		ctxt.rotate(@dir)
		@drawModel(ctxt, color(@color))
		ctxt.restore()

		# Color the hull depending on the cannon heat.
		if @cannonHeat > 0
			fillAlpha = @cannonHeat/@client.cannonCooldown
		else if @firePower > 0
			fillAlpha = (@firePower-@client.minPower)/(@client.maxPower-@client.minPower)

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
		if 	@name?  and @ isnt @client.localShip and
				(displayNames is on or
				@client.localShip.state is 'exploding' or @client.localShip.state is 'dead')
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

		@client.effects.push new ExplosionEffect(@client, @pos, @color, 200, 10, speed)

	drawOnRadar: (ctxt) ->
		# Select the closest ship position.
		bestDistance = Infinity
		for j in [-1..1]
			for k in [-1..1]
				x = @pos.x + j * @client.map.w
				y = @pos.y + k * @client.map.h
				d = distance(@client.localShip.pos.x, @client.localShip.pos.y, x, y)

				if d < bestDistance
					bestDistance = d
					bestPos = {x, y}

		dx = bestPos.x - @client.localShip.pos.x
		dy = bestPos.y - @client.localShip.pos.y

		# Draw the radar if the ship is outside of the screen bounds.
		if Math.abs(dx) > @client.canvasSize.w/2 or Math.abs(dy) > @client.canvasSize.h/2

			margin = 20
			rx = Math.max -@client.canvasSize.w/2 + margin, dx
			rx = Math.min @client.canvasSize.w/2 - margin, rx
			ry = Math.max -@client.canvasSize.h/2 + margin, dy
			ry = Math.min @client.canvasSize.h/2 - margin, ry

			radius = 10
			alpha = 1

			if @state is 'exploding'
				animRatio = 1 - @countdown / 1000
				radius -= animRatio * 10
				alpha -= animRatio

			ctxt.fillStyle = color(@color, alpha)
			ctxt.beginPath()
			ctxt.arc(@client.canvasSize.w/2 + rx, @client.canvasSize.h/2 + ry, radius, 0, 2*Math.PI, false)
			ctxt.fill()

		return true

# Exports
window.Ship = Ship
