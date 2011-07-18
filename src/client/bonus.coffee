class Bonus
	constructor: (@client, bonus) ->
		@serverUpdate(bonus)

	serverUpdate: (bonus) ->
		state_old = @state

		for field, val of bonus
			@[field] = val

		if @state is 'exploding' and state_old isnt 'exploding'
			@explode()

	update: () ->
		@clientDelete = @serverDelete

	inView: (offset = {x:0, y:0}) ->	
		@state isnt 'incoming' and
			@client.boxInView(@pos.x + offset.x, @pos.y + offset.y, 20)

	drawHitbox: (ctxt) ->
		ctxt.strokeStyle = 'red'
		ctxt.lineWidth = 1
		window.strokeCircle(ctxt, @pos.x, @pos.y, @hitRadius)

	draw: (ctxt) ->
		return if ['incoming','exploding','dead'].indexOf(@state) > -1

		ctxt.save()
		ctxt.translate(@pos.x, @pos.y)
		@drawModel(ctxt, color(@color))
		ctxt.restore()

	drawModel: (ctxt, col) ->

		ctxt.strokeStyle = col
		ctxt.fillStyle = 'white'
		ctxt.lineWidth = 2

		s = 20

		ctxt.fillRect(-s/2, -s/2, s, s)
		ctxt.strokeRect(-s/2, -s/2, s, s)

		ctxt.fillStyle = col

		switch @bonusType
			when 'bonusMine'
				ctxt.save()
				r = 5
				r2 = r*2
				ctxt.fillRect(-r, -r, r2, r2)
				ctxt.rotate(Math.PI/4)
				ctxt.fillRect(-r, -r, r2, r2)
				ctxt.restore()

			when 'bonusTracker'
				window.strokeCircle(ctxt, 0, 0, 1)
				window.strokeCircle(ctxt, 0, 0, 4)
				window.strokeCircle(ctxt, 0, 0, 7)

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
				ctxt.rotate(Math.PI)
				@drawArrow(ctxt)
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
				x = @pos.x + j * @client.map.w
				y = @pos.y + k * @client.map.h
				d = distance(@client.localShip.pos.x, @client.localShip.pos.y, x, y)

				if d < bestDistance
					bestDistance = d
					bestPos = {x, y}

		dx = bestPos.x - @client.localShip.pos.x
		dy = bestPos.y - @client.localShip.pos.y
		margin = 20

		# Draw the radar on the edges of the screen if the bonus is too far.
		if Math.abs(dx) > @client.canvasSize.w/2 or Math.abs(dy) > @client.canvasSize.h/2
			rx = Math.max -@client.canvasSize.w/2 + margin, dx
			rx = Math.min @client.canvasSize.w/2 - margin, rx
			ry = Math.max -@client.canvasSize.h/2 + margin, dy
			ry = Math.min @client.canvasSize.h/2 - margin, ry

			# The radar is blinking.
			if @countdown % 500 < 250
				@drawRadarSymbol(ctxt, @client.canvasSize.w/2 + rx, @client.canvasSize.h/2 + ry)

		# Draw the X on the future bonus position if it lies within the screen.
		else if @countdown % 500 < 250
			rx = -@client.canvasSize.w/2 + bestPos.x - @client.view.x
			ry = -@client.canvasSize.h/2 + bestPos.y - @client.view.y

			@drawRadarSymbol(ctxt, @client.canvasSize.w/2 + rx, @client.canvasSize.h/2 + ry)

		return true

	drawRadarSymbol: (ctxt, x, y) ->
		ctxt.save()
		ctxt.fillStyle = color @color
		ctxt.translate(x, y)
		ctxt.rotate(Math.PI/4)
		ctxt.fillRect(-4, -10, 8, 20)
		ctxt.rotate(Math.PI/2)
		ctxt.fillRect(-4, -10, 8, 20)
		ctxt.restore()

	explode: () ->
		# Launch explosion effect.
		@client.effects.push new ExplosionEffect(@client, @pos, @color, 50, 8)

		# Launch box opening effect.
		positions = [[0, -10], [10, 0], [0, 10], [-10, 0]]
		edges = []
		for i in [0..3]
			edges.push
				x: @pos.x + positions[i][0]
				y: @pos.y + positions[i][1]
				r: Math.PI/2 * i
				vx: positions[i][0] * 0.1
				vy: positions[i][1] * 0.1
				vr: (Math.random()*2-1) * 0.05
				size: 20
		@client.effects.push new DislocateEffect(@client, edges, @color, 1000)

# Exports
window.Bonus = Bonus
