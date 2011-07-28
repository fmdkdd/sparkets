class Shield
	constructor: (@client, shield) ->
		@serverUpdate(shield)

		# Create the sprite.
		s = 2*@boundingRadius
		color = window.utils.color @color
		@sprite = @client.spriteManager.get('shield', s, s, color)

	serverUpdate: (shield) ->
		for field, val of shield
			this[field] = val

		true

	update: () ->
		@clientDelete = @serverDelete

	inView: (offset = {x: 0, y: 0}) ->
		@client.boxInView(@pos.x + offset.x,
			@pos.y + offset.y, @boundingRadius)

	drawHitbox: (ctxt) ->
		ctxt.strokeStyle = 'red'
		ctxt.lineWidth = 1.1
		utils.strokeCircle(ctxt, @hitBox.x, @hitBox.y, @hitBox.radius)

	draw: (ctxt) ->
		ctxt.save()
		ctxt.translate(@pos.x, @pos.y)
		ctxt.drawImage(@sprite, -@sprite.width/2, -@sprite.height/2)
		ctxt.restore()

# Exports
window.Shield = Shield
