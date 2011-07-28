class Bonus
	constructor: (@client, bonus) ->
		@serverUpdate(bonus)

		# Create the bonus sprite.
		s = 2*@boundingRadius
		color = window.utils.color @color
		@sprite = @client.spriteManager.get('bonus', s, s, color)

		# Create the logo sprite and paste it on the bonus sprite.
		@logo = @client.spriteManager.get(@bonusType, 13, 13, color)
		@sprite.getContext('2d').drawImage(@logo, @sprite.width/2 - @logo.width/2, @sprite.height/2 - @logo.height/2)

	serverUpdate: (bonus) ->
		for field, val of bonus
			@[field] = val

		true

	update: () ->
		@clientDelete = @serverDelete

	inView: (offset = {x:0, y:0}) ->
		@state isnt 'incoming' and
			@client.boxInView(@pos.x + offset.x, @pos.y + offset.y, 20)

	drawHitbox: (ctxt) ->
		points = @hitBox.points
		return if points.length < 2

		ctxt.strokeStyle = 'red'
		ctxt.lineWidth = 1.1
		ctxt.beginPath()
		ctxt.moveTo(points[0].x, points[0].y)
		for i in [1...points.length]
			ctxt.lineTo(points[i].x, points[i].y)
		ctxt.closePath()
		ctxt.stroke()

	draw: (ctxt) ->
		return if @state isnt 'available' and @state isnt 'claimed'

		ctxt.save()
		ctxt.translate(@pos.x, @pos.y)
		@drawModel(ctxt, utils.color(@color))
		ctxt.restore()

	drawModel: (ctxt, col) ->
		ctxt.drawImage(@sprite, -@sprite.width/2, -@sprite.height/2)

		###
		switch @bonusType
			when 'bonusMine'
				ctxt.save()
				@drawMineIcon(ctxt)
				ctxt.restore()

			when 'bonusTracker'
				utils.strokeCircle(ctxt, 0, 0, 1)
				utils.strokeCircle(ctxt, 0, 0, 4)
				utils.strokeCircle(ctxt, 0, 0, 7)

			when 'bonusBoost'
				ctxt.save()
				ctxt.rotate(Math.PI/2)
				ctxt.translate(0, -6)
				@drawBoostIcon(ctxt)
				ctxt.restore()

			when 'bonusShield'
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

			when 'bonusEMP'
				ctxt.save()
				ctxt.beginPath()
				ctxt.moveTo(7, 0)
				ctxt.bezierCurveTo( 0,  0,  7,  7,  0,  7)
				ctxt.bezierCurveTo( 0,  0, -7,  7, -7,  0)
				ctxt.bezierCurveTo( 0,  0, -7, -7,  0, -7)
				ctxt.bezierCurveTo( 0,  0,  7, -7,  7,  0)
				ctxt.stroke()
				ctxt.restore()
		###

	drawMineIcon: (ctxt) ->
		r = 5
		r2 = r*2
		ctxt.fillRect(-r, -r, r2, r2)
		ctxt.rotate(Math.PI/4)
		ctxt.fillRect(-r, -r, r2, r2)

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

		bestPos = @client.closestGhost(@client.localShip.pos, @pos)
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
		ctxt.fillStyle = utils.color @color
		ctxt.translate(x, y)
		ctxt.rotate(Math.PI/4)
		ctxt.fillRect(-4, -10, 8, 20)
		ctxt.rotate(Math.PI/2)
		ctxt.fillRect(-4, -10, 8, 20)
		ctxt.restore()

	explosionEffect: () ->
		@client.effects.push new ExplosionEffect(@client, @pos, @color, 50, 8)

	openingEffect: () ->
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
