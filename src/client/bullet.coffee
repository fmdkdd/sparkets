class Bullet
	constructor: (@client, bullet) ->
		@clientPoints = []

		@serverUpdate (bullet)

		@color = @client.gameObjects[@ownerId].color

	serverUpdate: (bullet) ->
		utils.deepMerge(bullet, @)

		@clientPoints.push @lastPoint

	update: () ->
		@clientPoints.shift() if @serverDelete or @clientPoints.length > @client.maxBulletLength
		@clientDelete = yes if @serverDelete and @clientPoints.length == 0

	inView: (offset = {x: 0, y: 0}) ->
		# Bullets are culled from view on a segment basis
		# in @draw.
		true

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

	bulletWarp: (x1, y1, x2, y2) ->
		Math.abs(x1 - x2) > 50 or
			Math.abs(y1 - y2) > 50

	segmentInView: (x1, y1, x2, y2, offset = {x: 0, y: 0}) ->
		@client.inView(x1 + offset.x, y1 + offset.y) or
			@client.inView(x2  + offset.x, y2 + offset.y)

	drawSegment: (ctxt, x1, y1, x2, y2, alpha1, alpha2) ->
		gradient = ctxt.createLinearGradient(x1, y1, x2, y2)
		gradient.addColorStop(0, utils.color(@color, alpha1))
		gradient.addColorStop(1, utils.color(@color, alpha2))

		ctxt.strokeStyle = gradient
		ctxt.beginPath()
		ctxt.moveTo x1, y1
		ctxt.lineTo x2, y2
		ctxt.stroke()

	draw: (ctxt, offset = {x:0, y:0}) ->
		ctxt.lineWidth = 4
		ctxt.globalCompositeOperation = 'destination-over'

		p = @clientPoints
		x1 = p[0][0]
		y1 = p[0][1]

		for i in [1...p.length]
			x2 = p[i][0]
			y2 = p[i][1]

			if not @bulletWarp(x1, y1, x2, y2)
				if @segmentInView(x1, y1, x2, y2, offset)
					@drawSegment(ctxt, x1, y1, x2, y2, (i-1)/p.length, i/p.length)
			else
				unwarped = utils.unwarp({x: x1, y: y1}, {x: x2, y: y2}, @client.mapSize)
				@drawSegment(ctxt, x1, y1, unwarped.x, unwarped.y, (i-1)/p.length, i/p.length)

			x1 = x2
			y1 = y2


# Exports
window.Bullet = Bullet
