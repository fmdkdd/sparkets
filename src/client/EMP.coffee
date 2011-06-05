class EMP
	constructor: (emp) ->
		@serverUpdate(emp)

	serverUpdate: (emp) ->
		for field, val of emp
			this[field] = val

	update: () ->
		@clientDelete = @serverDelete

	draw: (ctxt, offset = {x:0, y:0}) ->
		x = @pos.x + offset.x
		y = @pos.y + offset.y
		f = @force

		if not window.inView(x+f, y+f) and
				not window.inView(x+f, y-f) and
				not window.inView(x-f, y+f) and
				not window.inView(x-f, y-f)
			return

		ctxt.save()

		ctxt.lineWidth = 3
		ctxt.strokeStyle = color @color
		ctxt.beginPath()
		ctxt.arc(x, y, f, 0, 2*Math.PI, false)
		ctxt.stroke()

		ctxt.restore()

# Exports
window.EMP = EMP
