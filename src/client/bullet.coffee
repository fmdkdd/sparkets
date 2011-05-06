class Bullet
	constructor: (bullet) ->
		@update(bullet)

		@frameSinceShift = 0

	update: (bullet) ->
		for field, val of bullet
			@[field] = val

		@points.push @lastPoint

	draw: (ctxt, alpha, offset = {x: 0, y: 0}) ->
		return if @points.length is 0

		p = @points
		ox = -view.x + offset.x
		oy = -view.y + offset.y

		x = p[0][0] + ox
		y = p[0][1] + oy
		ctxt.beginPath()
		ctxt.moveTo x, y

		for i in [1...p.length]
			ctxt.strokeStyle = color @color, i/p.length
			x = p[i][0] + ox
			y = p[i][1] + oy

			# Check for a bullet warping.
			if -50  < p[i-1][0] - p[i][0] < 50 and
					-50 < p[i-1][1] - p[i][1] < 50
				ctxt.lineTo x, y

			ctxt.stroke()
			ctxt.beginPath()
			ctxt.moveTo x, y

		if ++@frameSinceShift == bulletFrameStay
			@points.shift()
			@frameSinceShift = 0
