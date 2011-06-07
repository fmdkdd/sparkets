class EMP
	constructor: (emp) ->
		@serverUpdate(emp)

	serverUpdate: (emp) ->
		for field, val of emp
			this[field] = val

	update: () ->
		@clientDelete = @serverDelete

	inView: (offset = {x: 0, y: 0}) ->
		window.boxInView(@pos.x + offset.x,
			@pos.y + offset.y, @force)

	drawHitbox: (ctxt) ->


	draw: (ctxt) ->
		ctxt.lineWidth = 3
		ctxt.strokeStyle = color @color
		strokeCircle(ctxt, @pos.x, @pos.y, @force)

# Exports
window.EMP = EMP
