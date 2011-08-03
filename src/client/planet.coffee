class Planet
	constructor: (@client, planet) ->
		@serverUpdate(planet)

		# Create the sprite.
		s = 2 * @force
		color = window.utils.color @color
		@sprite = @client.spriteManager.get('planet', s, s, color)

	serverUpdate: (planet) ->
		utils.deepMerge(planet, @)

	update: () ->
		if @type is 'moon'
			@pos.x = @planet.pos.x + @dist * Math.cos(@angle)
			@pos.y = @planet.pos.y + @dist * Math.sin(@angle)

	inView: (offset = {x: 0, y: 0}) ->
		@client.boxInView(@pos.x + offset.x, @pos.y + offset.y, @force)

	drawHitbox: (ctxt) ->
		return if not @hitBox?

		ctxt.strokeStyle = 'red'
		ctxt.lineWidth = 1.1
		utils.strokeCircle(ctxt, @hitBox.x, @hitBox.y, @hitBox.radius)

		ctxt.fillStyle = 'black'
		ctxt.font = '15px sans'
		ctxt.fillText(@id, @pos.x - ctxt.measureText(@id).width/2, @pos.y)

	draw: (ctxt) ->
		ctxt.save()
		ctxt.translate(@pos.x, @pos.y)
		ctxt.drawImage(@sprite, -@sprite.width/2, -@sprite.height/2)
		ctxt.restore()


# Exports
window.Planet = Planet
