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

		if not window.inView(x+s, y+s) and
				not window.inView(x+s, y-s) and
				not window.inView(x-s, y+s) and
				not window.inView(x-s, y-s)
			return

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
				ctxt.rotate(Math.PI/2)
				ctxt.translate(0, -6)
				@drawBoostIcon(ctxt)
				ctxt.restore()

			when 'bonusEMP'
				ctxt.beginPath()
				ctxt.arc(0, 0, 3, 0, 2*Math.PI, false)
				ctxt.arc(0, 0, 7, 0, 2*Math.PI, false)
				ctxt.stroke()

			when 'bonusDrunk'
				ctxt.save()
				ctxt.translate(0, -3)
				@drawArrow(ctxt)
				ctxt.translate(0, 6)
				ctxt.save()
				ctxt.rotate(Math.PI)
				@drawArrow(ctxt)
				ctxt.restore()
				ctxt.restore()

		ctxt.restore()

	drawArrow: (ctxt) ->
		ctxt.beginPath()
		ctxt.moveTo(5, 0)
		ctxt.lineTo(-6, 0)
		ctxt.lineTo(-3, -3)
		ctxt.moveTo(-6, 0)
		ctxt.lineTo(-3, 3)
		ctxt.stroke()

	drawBoostIcon: (ctxt) ->
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
		return if @state isnt 'incoming'

		# Select the closest bonus among the real one and its ghosts.
		bestDistance = Infinity
		for j in [-1..1]
			for k in [-1..1]
				x = @pos.x + j * window.map.w
				y = @pos.y + k * window.map.h
				d = distance(window.localShip.pos.x, window.localShip.pos.y, x, y)

				if d < bestDistance
					bestDistance = d
					bestPos = {x, y}

		dx = bestPos.x - window.localShip.pos.x
		dy = bestPos.y - window.localShip.pos.y
		margin = 20

		# Draw the radar on the edges of the screen if the bonus is too far.
		if Math.abs(dx) > window.screen.w/2 or Math.abs(dy) > window.screen.h/2
			rx = Math.max -window.screen.w/2 + margin, dx
			rx = Math.min window.screen.w/2 - margin, rx
			ry = Math.max -window.screen.h/2 + margin, dy
			ry = Math.min window.screen.h/2 - margin, ry

			# The radar is blinking.
			if @countdown % 500 < 250
				@drawRadarSymbol(ctxt, window.screen.w/2 + rx, window.screen.h/2 + ry)

		# Draw the X on the future bonus position if it lies within the screen.
		else if @countdown % 500 < 250
			rx = -window.screen.w/2 + bestPos.x - window.view.x
			ry = -window.screen.h/2 + bestPos.y - window.view.y

			@drawRadarSymbol(ctxt, window.screen.w/2 + rx, screen.h/2 + ry)

		return true

	drawRadarSymbol: (ctxt, x, y) ->
		ctxt.fillStyle = color @color
		ctxt.save()
		ctxt.translate(x, y)
		ctxt.rotate(Math.PI/4)
		ctxt.fillRect(-4, -10, 8, 20)
		ctxt.rotate(Math.PI/2)
		ctxt.fillRect(-4, -10, 8, 20)
		ctxt.restore()

		return true

# Exports
window.Bonus = Bonus
