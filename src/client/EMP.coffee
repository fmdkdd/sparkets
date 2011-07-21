class EMP
	constructor: (@client, emp) ->
		@serverUpdate(emp)

	serverUpdate: (emp) ->
		for field, val of emp
			this[field] = val

	update: () ->
		@clientDelete = @serverDelete

	inView: (offset = {x: 0, y: 0}) ->
		@client.boxInView(@pos.x + offset.x,
			@pos.y + offset.y, @force)

	drawHitbox: (ctxt) ->
		ctxt.strokeStyle = 'red'
		ctxt.lineWidth = 1
		utils.strokeCircle(ctxt, @hitBox.x, @hitBox.y, @hitBox.radius)

	draw: (ctxt) ->
		ctxt.lineWidth = 3
		ctxt.strokeStyle = utils.color @color
		utils.strokeCircle(ctxt, @pos.x, @pos.y, @force)

# Exports
window.EMP = EMP
