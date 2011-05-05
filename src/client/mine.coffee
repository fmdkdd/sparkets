class Mine
	constructor: (mine) ->
		@state = mine.state
		@pos = mine.pos
		@color = mine.color
		@modelRadius = mine.modelRadius
		@detectionRadius = mine.detectionRadius
		@explosionRadius = mine.explosionRadius
		@countdown = mine.countdown

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
		div = 2

		if not inView(x+dr, y+dr) and
				not inView(x+dr, y-dr) and
				not inView(x-dr, y+dr) and
				not inView(x-dr, y-dr)
			return

		x -= view.x
		y -= view.y

		# Make the mine grow during the activation process.
		r -= r * @countdown / 1000 if @state is 'inactive'

		# Draw the body of the mine.
		ctxt.fillStyle = color @color
		ctxt.save()
		ctxt.translate(x, y)
		for i in [0...div]
			ctxt.beginPath()
			ctxt.rotate(Math.PI/2/div)
			ctxt.fillRect(-r, -r, r*2, r*2)
			ctxt.fill()
		ctxt.restore()

		# Draw the sensor waves when the mine is active.
		if @state is 'active'
			t = (new Date).getTime()
			ctxt.save()
			ctxt.lineWidth = 2
			for i in [0..2]
				animRatio = ((t-i*3333) % 10000) / 10000
				ctxt.strokeStyle = color(@color, 1 - animRatio)
				ctxt.beginPath()
				ctxt.arc(x, y, animRatio * dr, 0, 2*Math.PI, false)
				ctxt.stroke()
			ctxt.restore()

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
