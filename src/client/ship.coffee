class Ship
	constructor: (@client, ship) ->
		@serverUpdate(ship)

		@engineAnimFor = null
		@engineAnimDelay = 200

		# Create the sprite.
		w = 20+5 # +5 to make way for the line width and the line rounding.
		h = 14+5
		color = window.utils.color @color
		@sprite = @client.spriteManager.get('ship', w, h, color)

	serverUpdate: (ship) ->
		thrust_old = @thrust

		utils.deepMerge(ship, @)

		# Start the engine fade-in/out in the ship just started/stopped thrusting.
		if @thrust isnt thrust_old
			@engineAnimFor = @engineAnimDelay

	update: () ->
		# Update the engine animation.
		if @engineAnimFor?
			@engineAnimFor -= @client.sinceLastUpdate
			@engineAnimFor = null if @engineAnimFor <= 0

	inView: (offset = {x:0, y:0}) ->
		@client.boxInView(@pos.x + offset.x, @pos.y + offset.y, 10)

	drawHitbox: (ctxt) ->
		points = @hitBox.points
		return if points.length < 2

		ctxt.strokeStyle = 'red'
		ctxt.lineWidth = 1.1
		ctxt.beginPath()
		ctxt.moveTo(points[0].x, points[0].y)
		for i in [1...points.length]
			ctxt.lineTo(points[i].x, points[i].y)
		ctxt.closePath()
		ctxt.stroke()

	draw: (ctxt) ->
		return if @state is 'dead' or @state is 'ready'

		# Blink when the ship just spawned.
		return if @state is 'spawned' and @client.now % 200 < 100

		if @invisible and @ isnt @client.localShip
			# Maybe draw a stealthy effect instead of the ship.
			return
		else
			# Draw the basic model.
			ctxt.save()
			ctxt.translate(@pos.x, @pos.y)
			ctxt.rotate(@dir)
			ctxt.globalAlpha = 0.5 if @invisible
			ctxt.drawImage(@sprite, -@sprite.width/2, -@sprite.height/2)
			ctxt.restore()

		# Color the hull depending on the cannon heat.
		if @cannonHeat > 0
			fillAlpha = @cannonHeat/@client.cannonCooldown
		else if @firePower > 0
			fillAlpha = (@firePower-@client.minPower)/(@client.maxPower-@client.minPower)

		fillAlpha /= 2 if @invisible

		points = [[-10,-7], [10,0], [-10,7], [-6,0]]
		ctxt.save()
		ctxt.translate(@pos.x, @pos.y)
		ctxt.rotate(@dir)
		ctxt.fillStyle = utils.color(@color, fillAlpha)
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

			alpha /= 2 if @invisible

			ctxt.strokeStyle = utils.color(@color, alpha)
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
				(@client.displayNames or @client.localShip.state is 'dead')
			ctxt.fillStyle = '#666'
			ctxt.font = '15px sans'
			ctxt.fillText(@name, @pos.x - ctxt.measureText(@name).width/2, @pos.y - 25)

	drawOnRadar: (ctxt) ->
		return if @invisible

		bestPos = @client.closestGhost(@client.localShip.pos, @pos)
		dx = bestPos.x - @client.localShip.pos.x
		dy = bestPos.y - @client.localShip.pos.y

		# Draw the radar if the ship is outside of the screen bounds.
		if Math.abs(dx) > @client.canvasSize.w/2 or Math.abs(dy) > @client.canvasSize.h/2

			margin = 20
			rx = Math.max -@client.canvasSize.w/2 + margin, dx
			rx = Math.min @client.canvasSize.w/2 - margin, rx
			ry = Math.max -@client.canvasSize.h/2 + margin, dy
			ry = Math.min @client.canvasSize.h/2 - margin, ry

			# Scale radius with the inverse distance, but ensure a
			# minimum radius of 3.
			dist = Math.sqrt(dx*dx + dy*dy) - Math.sqrt(rx*rx + ry*ry)
			halfMap = @client.mapSize/2
			distRatio = (halfMap - dist) / halfMap
			radius = 3 + 10 * distRatio
			alpha = 1

			ctxt.fillStyle = utils.color(@color, alpha)
			ctxt.beginPath()
			ctxt.arc(@client.canvasSize.w/2 + rx, @client.canvasSize.h/2 + ry, radius, 0, 2*Math.PI, false)
			ctxt.fill()

		return true

	boostEffect: () ->
		@client.effects.push new BoostEffect(@client, @, 5, 3000)

	killingSpeed: () ->
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
		Math.max(speed, 3)

	explosionEffect: () ->
		speed = @killingSpeed()

		@client.effects.push new ExplosionEffect(@client, @pos, @color, 200, 10, speed)

	dislocationEffect: () ->
		points = [
			{x: -10, y: -7},
			{x: 10, y: -0},
			{x: -10, y: 7},
			{x: -6, y: 0}]

		edges = []

		speed = @killingSpeed()

		# Rotate points according to the direction of the ship.
		for p in points
			p = utils.vec.rotate(p, @dir)

		# Loop through the points to build edges.
		for i in [0...points.length]
			cur = points[i]
			next = points[(i+1) % points.length]
			middle =
				x: cur.x + (next.x - cur.x) / 2
				y: cur.y + (next.y - cur.y) / 2
			angle = Math.atan2(next.y-cur.y, next.x-cur.x)

			edges.push
				x: @pos.x + middle.x
				y: @pos.y + middle.y
				r: angle
				vx: middle.x * 0.05 * speed * Math.random()
				vy: middle.y * 0.05 * speed * Math.random()
				vr: (Math.random()*2-1) * 0.05
				size: utils.distance(cur.x, cur.y, next.x, next.y)
				lineWidth: 4

		@client.effects.push new DislocateEffect(@client, edges, @color, 5000)

	EMPEffect: () ->
		# Immobile flash effect.
		staticPos = {x: @pos.x, y: @pos.y}
		@client.effects.push new FlashEffect(@client, staticPos, 300, @color, 600)

# Exports
window.Ship = Ship
