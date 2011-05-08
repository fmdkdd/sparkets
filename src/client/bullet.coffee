class Bullet
	constructor: (bullet) ->
		@update(bullet)

	update: (bullet) ->
		for field, val of bullet
			@[field] = val

		for p in @lastPoints
			@points.push p

	draw: (ctxt, offset = {x: 0, y: 0}) ->
		if @points.length is 0
			@clientDelete = yes if @points.length == 0
			return

		p = @points
		ox = -view.x + offset.x
		oy = -view.y + offset.y

		x = p[0][0] + ox
		y = p[0][1] + oy
		ctxt.lineWidth = 4
		ctxt.globalCompositeOperation = 'destination-over'
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

		ctxt.globalCompositeOperation = 'source-over'

		if showHitCircles
			ctxt.strokeStyle = 'red'
			ctxt.lineWidth = 1
			strokeCircle(ctxt, x, y, @hitRadius)

		@points.shift() if @tailTrim or @points.length > maxBulletLength
