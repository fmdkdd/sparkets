class Planet
	constructor: (planet) ->
		@pos = planet.pos
		@force = planet.force
	
	draw: (ctxt, offset = x:0, y:0) ->
		px = @pos.x + offset.x
		py = @pos.y + offset.y
		f = @force;

		return if !inView(px + f, py + f) && !inView(px + f, py - f) && !inView(px - f, py + f) && !inView(px - f, py - f)

		x = px - view.x
		y = py - view.y

		ctxt.strokeStyle = color(planetColor)
		ctxt.beginPath()
		ctxt.arc(x, y, f, 0, 2*Math.PI, false)
		ctxt.stroke()
