class Planet
	constructor: (planet) ->
		@serverUpdate(planet)

		@initSprite() if not @sprite?

	initSprite: () ->
		@sprite = document.createElement('canvas')
		@sprite.width = @sprite.height = Math.ceil(2*@force)

		c = @sprite.getContext('2d')
		c.strokeStyle = color window.planetColor
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

	inView: (offset = {x: 0, y: 0}) ->
		window.boxInView(@pos.x + offset.x,
			@pos.y + offset.y, @force)

	drawHitbox: (ctxt) ->
		ctxt.strokeStyle = 'red'
		ctxt.lineWidth = 1
		strokeCircle(ctxt, @pos.x, @pos.y, @hitRadius)

		ctxt.fillStyle = 'black'
		ctxt.font = '15px sans'
		ctxt.fillText(@id, @pos.x - ctxt.measureText(@id).width/2, @pos.y)

	draw: (ctxt) ->
		x = @pos.x
		y = @pos.y
		f = @force;

		# Fix jiggling planets?
		ctxt.translate(x-f, y-f)
		ctxt.drawImage(@sprite, 0, 0)

# Exports
window.Planet = Planet
