class Shield
	constructor: (@client, shield) ->
		@serverUpdate(shield)

	serverUpdate: (shield) ->
		for field, val of shield
			this[field] = val

		true

	update: () ->
		@clientDelete = @serverDelete

	inView: (offset = {x: 0, y: 0}) ->
		@client.boxInView(@pos.x + offset.x,
			@pos.y + offset.y, @hitBox.radius)

	drawHitbox: (ctxt) ->
		ctxt.strokeStyle = 'red'
		ctxt.lineWidth = 1.1
		utils.strokeCircle(ctxt, @hitBox.x, @hitBox.y, @hitBox.radius)

	draw: (ctxt) ->
		ctxt.lineWidth = 3
		ctxt.strokeStyle = utils.color @color
		utils.strokeCircle(ctxt, @pos.x, @pos.y, @hitBox.radius)

# Exports
window.Shield = Shield
