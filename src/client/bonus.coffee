class Bonus
	constructor: (bonus) ->
		@update(bonus)

	update: (bonus) ->
		for field, val of bonus
			@[field] = val

	draw: (ctxt, offset = {x:0, y:0}) ->
		return if @state is 'dead'

		x = @pos.x + offset.x
		y = @pos.y + offset.y
		s = @modelSize
		r = 5

		if not inView(x+s, y+s) and
				not inView(x+s, y-s) and
				not inView(x-s, y+s) and
				not inView(x-s, y-s)
			return

		x -= view.x
		y -= view.y

		ctxt.fillStyle = color @color
		ctxt.strokeStyle = color @color
		ctxt.lineWidth = 2
		ctxt.save()
		ctxt.translate(x, y)
		ctxt.strokeRect(-s/2, -s/2, s, s)
		ctxt.fillRect(-r, -r, r*2, r*2)
		ctxt.rotate(Math.PI/4)
		ctxt.fillRect(-r, -r, r*2, r*2)
		ctxt.restore()

	drawOnRadar: (ctxt) ->
		localShip = ships[id]

		# Select the closest bonus among the real one and its ghosts.
		bestDistance = Infinity
		for j in [-1..1]
			for k in [-1..1]
				x = @pos.x + j * map.w
				y = @pos.y + k * map.h
				d = distance(localShip.pos.x, localShip.pos.y, x, y)

				if d < bestDistance
					bestDistance = d
					bestPos = {x, y}

		dx = bestPos.x - localShip.pos.x
		dy = bestPos.y - localShip.pos.y

		# Draw the radar if the bonus is outside of the screen bounds.
		if Math.abs(dx) > screen.w/2 or Math.abs(dy) > screen.h/2

			margin = 20
			rx = Math.max -screen.w/2 + margin, dx
			rx = Math.min screen.w/2 - margin, rx
			ry = Math.max -screen.h/2 + margin, dy
			ry = Math.min screen.h/2 - margin, ry

			ctxt.fillStyle = color @color
			ctxt.save()
			ctxt.translate(screen.w/2 + rx, screen.h/2 + ry)
			ctxt.rotate(Math.PI/4)
			ctxt.fillRect(-4, -10, 8, 20)
			ctxt.rotate(Math.PI/2)
			ctxt.fillRect(-4, -10, 8, 20)
			ctxt.restore()

		return true
