class Planet
	constructor: (planet) ->
		@serverUpdate(planet)

		@initSprite() if not @sprite?

	initSprite: () ->
		@sprite = document.createElement('canvas')
		@sprite.width = @sprite.height = Math.ceil(2*@force)

		c = @sprite.getContext('2d')
		c.strokeStyle = color planetColor
		c.fillStyle = 'white'
		c.lineWidth = 8
		c.beginPath()
		c.arc(@force, @force, @force - c.lineWidth/2, 0, 2*Math.PI, false)
		c.stroke()
		c.fill()

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

		ctxt.drawImage(@sprite, x-f, y-f)

		if showHitCircles
			ctxt.strokeStyle = 'red'
			ctxt.lineWidth = 1
			strokeCircle(ctxt, x, y, @hitRadius)

# Exports
window.Planet = Planet
