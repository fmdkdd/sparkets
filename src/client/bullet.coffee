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

	draw: (ctxt, offset = {x: 0, y: 0}) ->
		p = @points
		ox = -window.view.x + offset.x
		oy = -window.view.y + offset.y

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
					-50 < p[i-1][1] - p[i][1] < 50 and
					(window.inView(x+window.view.x, y+window.view.y) or
						window.inView(p[i-1][0]+offset.x, p[i-1][1]+offset.y))
					ctxt.lineTo x, y

			ctxt.stroke()
			ctxt.beginPath()
			ctxt.moveTo x, y

		ctxt.globalCompositeOperation = 'source-over'

		if window.showHitCircles
			ctxt.strokeStyle = 'red'
			ctxt.lineWidth = 1
			strokeCircle(ctxt, x, y, @hitRadius)

# Exports

window.Bullet = Bullet
