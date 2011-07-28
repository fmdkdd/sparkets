class Planet
	constructor: (@client, planet) ->
		@serverUpdate(planet)

		# Create the sprite.
		s = 2*@boundingRadius
		color = window.utils.color @color
		@sprite = @client.spriteManager.get('planet', s, s, color)

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
