class Bonus
	constructor: (@client, bonus) ->
		@serverUpdate(bonus)

		# Create the bonus sprite.
		@radius = 10
		s = 2*@radius
		color = window.utils.color @color
		@sprite = @client.spriteManager.get('bonus', s, s, color)

		# Create the logo sprite and paste it on the bonus sprite.
		@logo = @client.spriteManager.get(@bonusType, 13, 13, color)
		@sprite.getContext('2d').drawImage(@logo, @sprite.width/2 - @logo.width/2, @sprite.height/2 - @logo.height/2)

	serverUpdate: (bonus) ->
		utils.deepMerge(bonus, @)

	update: () ->
		@clientDelete = @serverDelete

	inView: (offset = {x:0, y:0}) ->
		@state isnt 'incoming' and
			@client.boxInView(@pos.x + offset.x, @pos.y + offset.y, @radius)

	drawHitbox: (ctxt) ->
		return if not @hitBox?

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
		ctxt.globalCompositeOperation = 'destination-over'
		ctxt.drawImage(@sprite, -@sprite.width/2, -@sprite.height/2)
		ctxt.restore()

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

			# Scale the symbol with the inverse distance, but ensure a
			# minimum scale of 0.5.
			dist = Math.sqrt(dx*dx + dy*dy) - Math.sqrt(rx*rx + ry*ry)
			halfMap = @client.mapSize/2
			distRatio = (halfMap - dist) / halfMap
			scale = Math.max(.5, distRatio)

			# The radar is blinking.
			if @countdown % 500 < 250
				@drawRadarSymbol(ctxt, @client.canvasSize.w/2 + rx,
					@client.canvasSize.h/2 + ry, scale)

		# Draw the X on the future bonus position if it lies within the screen.
		else if @countdown % 500 < 250
			rx = -@client.canvasSize.w/2 + bestPos.x - @client.view.x
			ry = -@client.canvasSize.h/2 + bestPos.y - @client.view.y

			@drawRadarSymbol(ctxt, @client.canvasSize.w/2 + rx, @client.canvasSize.h/2 + ry)

		return true

	drawRadarSymbol: (ctxt, x, y, scale = 1) ->
		ctxt.save()
		ctxt.fillStyle = utils.color @color
		ctxt.translate(x, y)
		ctxt.scale(scale, scale)
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
				vx: positions[i][0] * 0.05 * Math.random()
				vy: positions[i][1] * 0.05 * Math.random()
				vr: (Math.random()*2-1) * 0.05
				size: 20
		@client.effects.push new DislocateEffect(@client, edges, @color, 1000)

# Exports
window.Bonus = Bonus
