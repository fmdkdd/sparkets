class Bullet
	constructor: (bullet) ->
		@serverUpdate (bullet)

	serverUpdate: (bullet) ->
		for field, val of bullet
			@[field] = val

		@points.push p for p in @lastPoints

	update: () ->
		@points.shift() if @serverDelete or @points.length > window.maxBulletLength
		@clientDelete = yes if @points.length == 0

	inView: (offset = {x: 0, y: 0}) ->
		# Bullets are culled from view on a segment basis
		# in @draw.
		true

	drawHitbox: (ctxt) ->
		ctxt.strokeStyle = 'red'
		ctxt.lineWidth = 1
		lastPoint = @points[@points.length-1]
		strokeCircle(ctxt, lastPoint[0], lastPoint[1], @hitRadius)

	bulletWrap: (x1, y1, x2, y2) ->
		Math.abs(x1 - x2) > 50 or
			Math.abs(y1 - y2) > 50

	drawSegment: (ctxt, x1, y1, x2, y2, alpha1, alpha2) ->
		gradient = ctxt.createLinearGradient(x1, y1, x2, y2)
		gradient.addColorStop(0, color(@color, alpha1))
		gradient.addColorStop(1, color(@color, alpha2))

		ctxt.strokeStyle = gradient
		ctxt.beginPath()
		ctxt.moveTo x1, y1
		ctxt.lineTo x2, y2
		ctxt.stroke()

	draw: (ctxt) ->
		ctxt.lineWidth = 4
		ctxt.globalCompositeOperation = 'destination-over'

		p = @points
		x1 = p[0][0]
		y1 = p[0][1]

		for i in [1...p.length]
			x2 = p[i][0]
			y2 = p[i][1]

			if not @bulletWrap(x1, y1, x2, y2)
				@drawSegment(ctxt, x1, y1, x2, y2, (i-1)/p.length, i/p.length)

			x1 = x2
			y1 = y2

		ctxt.globalCompositeOperation = 'source-over'

# Exports

window.Bullet = Bullet
