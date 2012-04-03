class Shield
	constructor: (@client, shield) ->
		@serverUpdate(shield)

		# Take color from owner.
		@owner = @client.gameObjects[@ownerId]
		@color = @owner.color
		@pos = @owner.pos

		# Create the sprite.
		s = 2*@force
		color = utils.color @color
		@sprite = @client.spriteManager.get('shield', s, s, color)

	serverUpdate: (shield) ->
		utils.deepMerge(shield, @)

	update: () ->
		@clientDelete = @serverDelete

	inView: (offset = {x: 0, y: 0}) ->
		@client.boxInView(@pos.x + offset.x, @pos.y + offset.y, @force)

	drawHitbox: (ctxt) ->
		return if not @hitBox?

		ctxt.strokeStyle = 'red'
		ctxt.lineWidth = 1.1
		utils.strokeCircle(ctxt, @hitBox.x, @hitBox.y, @hitBox.radius)

	draw: (ctxt) ->
		# When the holder is invisible, hide from other ships
		# and draw a special effect if the client is the holder
		if @owner.invisible
			if @owner is @client.localShip
				ctxt.globalAlpha = 0.5
			else
				return

		ctxt.save()
		ctxt.translate(@pos.x, @pos.y)
		ctxt.drawImage(@sprite, -@sprite.width/2, -@sprite.height/2)
		ctxt.restore()

# Exports
window.Shield = Shield
