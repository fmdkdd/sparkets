class Planet
	constructor: (planet) ->
		@serverUpdate(planet)

		@initSprite() if not @sprite?

	initSprite: () ->
		@sprite = document.createElement('canvas')
		@sprite.width = @sprite.height = 200
		
		spriteCtxt = @sprite.getContext('2d')
		spriteCtxt.strokeStyle = color planetColor
		spriteCtxt.fillStyle = 'white'
		spriteCtxt.lineWidth = 8
		spriteCtxt.beginPath()
		spriteCtxt.arc(@force, @force, @force - spriteCtxt.lineWidth/2, 0, 2*Math.PI, false)
		spriteCtxt.stroke()
		spriteCtxt.fill()

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

		ctxt.save()
		ctxt.translate(x-f,y-f)
		ctxt.drawImage(@sprite, 0, 0)
		ctxt.restore()

		if showHitCircles
			ctxt.strokeStyle = 'red'
			ctxt.lineWidth = 1
			strokeCircle(ctxt, x, y, @hitRadius)
