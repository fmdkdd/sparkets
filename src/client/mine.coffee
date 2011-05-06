class Mine
	constructor: (mine) ->
		@update(mine)

		@waves = [0, -@detectionRadius/3, -2*@detectionRadius/3]

	update: (mine) ->
		for field, val of mine
			this[field] = val

	draw: (ctxt, offset) ->
		if @state is 'inactive' or @state is 'active'
			@drawMine(ctxt, offset)
		else if @state is 'exploding'
			@drawExplosion(ctxt, offset)

	drawMine: (ctxt, offset = {x:0, y:0}) ->
		x = @pos.x + offset.x
		y = @pos.y + offset.y
		r = @modelRadius
		dr = @detectionRadius

		if not inView(x+dr, y+dr) and
				not inView(x+dr, y-dr) and
				not inView(x-dr, y+dr) and
				not inView(x-dr, y-dr)
			return

		x -= view.x
		y -= view.y

		# Make the mine grow during the activation process.
		if @state is 'inactive'
			r -= r * @countdown / 1000

		# Draw the body of the mine.
		ctxt.fillStyle = color @color
		ctxt.save()
		ctxt.translate(x, y)
		ctxt.fillRect(-r, -r, r*2, r*2)
		ctxt.rotate(Math.PI/4)
		ctxt.fillRect(-r, -r, r*2, r*2)
		ctxt.restore()

		# Draw the sensor waves when the mine is active.
		if @state is 'active'
			ctxt.lineWidth = 2
			for i in [0..@waves.length]
				if @waves[i] > 0
					ctxt.strokeStyle = color(@color, 1-@waves[i]/@detectionRadius)
					ctxt.beginPath()
					ctxt.arc(x, y, @waves[i], 0, 2*Math.PI, false)
					ctxt.stroke()

				# Step the wave.
				@waves[i] += 0.3
				@waves[i] = 0 if @waves[i] > @detectionRadius

	drawExplosion: (ctxt, offset = {x:0, y:0}) ->
		x = @pos.x + offset.x
		y = @pos.y + offset.y
		animRatio = 1 - @countdown / 500
		r = @explosionRadius
		a = 1 - animRatio

		if not inView(x+r, y+r) and
				not inView(x+r, y-r) and
				not inView(x-r, y+r) and
				not inView(x-r, y-r)
			return

		x -= view.x
		y -= view.y

		ctxt.fillStyle = color(@color, a)
		ctxt.beginPath()
		ctxt.arc(x, y, r, 0, 2*Math.PI, false)
		ctxt.fill()
