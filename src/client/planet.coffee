class Planet
	constructor: (@client, planet) ->
		@serverUpdate(planet)

		@initSprite() if not @sprite?

	initSprite: () ->
		r = @boundingRadius

		@sprite = document.createElement('canvas')
		@sprite.width = @sprite.height = Math.ceil(2*r)

		c = @sprite.getContext('2d')
		c.strokeStyle = utils.color @color
		c.fillStyle = 'white'
		c.lineWidth = 8
		c.beginPath()
		c.arc(r, r, r - c.lineWidth/2, 0, 2*Math.PI, false)
		c.stroke()
		c.fill()

	serverUpdate: (planet) ->
		for field, val of planet
			@[field] = val

		true

	update: () ->

	inView: (offset = {x: 0, y: 0}) ->
		@client.boxInView(@pos.x + offset.x, @pos.y + offset.y, @boundingRadius)

	drawHitbox: (ctxt) ->
		ctxt.strokeStyle = 'red'
		ctxt.lineWidth = 1.1
		utils.strokeCircle(ctxt, @hitBox.x, @hitBox.y, @hitBox.radius)

		ctxt.fillStyle = 'black'
		ctxt.font = '15px sans'
		ctxt.fillText(@id, @pos.x - ctxt.measureText(@id).width/2, @pos.y)

	draw: (ctxt) ->
		r = @boundingRadius

		ctxt.save()
		ctxt.translate(@pos.x - r, @pos.y - r)
		@drawModel(ctxt, null)
		ctxt.restore()

	drawModel: (ctxt, col) ->
		ctxt.drawImage(@sprite, 0, 0)

# Exports
window.Planet = Planet
