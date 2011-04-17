class Planet
	constructor: (planet) ->
		@pos = planet.pos
		@force = planet.force
	
	draw: (ctxt, offset = {x: 0, y: 0}) ->
		px = @pos.x + offset.x
		py = @pos.y + offset.y
		f = @force;

		# Compute the closest point of the planet from the ship.
		dx = ships[id].pos.x - px
		dy = ships[id].pos.y - py
		d = Math.sqrt dx*dx+dy*dy
		ndx = px + dx / d * f
		ndy = py + dy / d * f

		# Check the planet really needs to be drawn.
		if not inView ndx, ndy then return

		x = px - view.x
		y = py - view.y

		ctxt.strokeStyle = color planetColor
		ctxt.beginPath()
		ctxt.arc x, y, f, 0, 2*Math.PI, false
		ctxt.stroke()
