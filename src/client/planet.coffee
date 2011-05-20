class Planet
	constructor: (planet) ->
		@serverUpdate(planet)

	serverUpdate: (planet) ->
		for field, val of planet
			@[field] = val

	update: () ->
		true

	draw: (ctxt, offset = {x: 0, y: 0}) ->
		px = @pos.x + offset.x
		py = @pos.y + offset.y
		f = @force;

		# Check the planet really needs to be drawn.
		if not inView(px+f, py+f) and
				not inView(px+f, py-f) and
				not inView(px-f, py+f) and
				not inView(px-f, py-f)
			return

		x = px - view.x
		y = py - view.y

		if showHitCircles
			ctxt.strokeStyle = 'red'
			ctxt.lineWidth = 1
			strokeCircle(ctxt, x, y, @hitRadius)

		ctxt.strokeStyle = color planetColor
		ctxt.fillStyle = 'white'
		ctxt.lineWidth = 8
		ctxt.beginPath()
		ctxt.arc x, y, f, 0, 2*Math.PI, false
		ctxt.stroke()
		ctxt.fill()

