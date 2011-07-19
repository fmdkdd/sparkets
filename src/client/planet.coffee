class Planet
	constructor: (@client, planet) ->
		@serverUpdate(planet)

		@initSprite() if not @sprite?

	initSprite: () ->
		@sprite = document.createElement('canvas')
		@sprite.width = @sprite.height = Math.ceil(2*@force)

		c = @sprite.getContext('2d')
		c.strokeStyle = color @color
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

	inView: (offset = {x: 0, y: 0}) ->
		@client.boxInView(@pos.x + offset.x, @pos.y + offset.y, @force)

	drawHitbox: (ctxt) ->
		ctxt.strokeStyle = 'red'
		ctxt.lineWidth = 1
		strokeCircle(ctxt, @pos.x, @pos.y, @hitRadius)

		ctxt.fillStyle = 'black'
		ctxt.font = '15px sans'
		ctxt.fillText(@id, @pos.x - ctxt.measureText(@id).width/2, @pos.y)

	draw: (ctxt) ->
		ctxt.save()
		ctxt.translate(@pos.x - @force, @pos.y - @force)
		@drawModel(ctxt, null)
		ctxt.restore()

	drawModel: (ctxt, col) ->
		ctxt.drawImage(@sprite, 0, 0)

# Exports
window.Planet = Planet
