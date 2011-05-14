class Bonus
	constructor: (bonus) ->
		@serverUpdate(bonus)

	serverUpdate: (bonus) ->
		for field, val of bonus
			@[field] = val

	update: () ->
		@clientDelete = @serverDelete

	draw: (ctxt, offset = {x:0, y:0}) ->
		return if @state is 'incoming'

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

		if showHitCircles
			ctxt.strokeStyle = 'red'
			ctxt.lineWidth = 1
			strokeCircle(ctxt, x, y, @hitRadius)

		ctxt.fillStyle = color @color
		ctxt.strokeStyle = color @color

		ctxt.lineWidth = 2
		ctxt.save()
		ctxt.translate(x, y)
		ctxt.strokeRect(-s/2, -s/2, s, s)

		switch @bonusType
			when 'bonusMine'
				ctxt.fillRect(-r, -r, r*2, r*2)
				ctxt.rotate(Math.PI/4)
				ctxt.fillRect(-r, -r, r*2, r*2)

			when 'bonusBoost'
				ctxt.save()
				ctxt.translate(0, -6)
				@drawArrow(ctxt)
				ctxt.restore()

		ctxt.restore()

	drawArrow: (ctxt) ->
		ctxt.beginPath()
		ctxt.moveTo(0, 0)
		ctxt.lineTo(-6, 6)
		ctxt.lineTo(-2, 6)
		ctxt.lineTo(-6, 11)
		ctxt.lineTo( 6, 11)
		ctxt.lineTo( 2, 6)
		ctxt.lineTo( 6, 6)
		ctxt.closePath()
		ctxt.fill()

	drawOnRadar: (ctxt) ->
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
		margin = 20

		# Draw the radar on the edges of the screen if the bonus is too far.
		if Math.abs(dx) > screen.w/2 or Math.abs(dy) > screen.h/2
			rx = Math.max -screen.w/2 + margin, dx
			rx = Math.min screen.w/2 - margin, rx
			ry = Math.max -screen.h/2 + margin, dy
			ry = Math.min screen.h/2 - margin, ry

			# The radar is blinking when the bonus is incoming.
			if @state is 'active' or
					@state is 'incoming' and @countdown % 500 < 250
				@drawRadarSymbol(screen.w/2 + rx, screen.h/2 + ry)

		# Draw the radar on the future bonus position if it is in the screen
		# bounds and incoming.
		else if @state is 'incoming' and @countdown % 500 < 250
			rx = -screen.w/2 + bestPos.x - view.x
			ry = -screen.h/2 + bestPos.y - view.y

			@drawRadarSymbol(screen.w/2 + rx, screen.h/2 + ry)

		return true

	drawRadarSymbol: (x, y) ->
		ctxt.fillStyle = color @color
		ctxt.save()
		ctxt.translate(x, y)
		ctxt.rotate(Math.PI/4)
		ctxt.fillRect(-4, -10, 8, 20)
		ctxt.rotate(Math.PI/2)
		ctxt.fillRect(-4, -10, 8, 20)
		ctxt.restore()

		return true
