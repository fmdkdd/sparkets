class Bullet
	constructor: (bullet) ->
		@owner = bullet.owner

		@pos = bullet.pos
		@accel = bullet.accel
		@power = bullet.power

		@color = bullet.color
		@points = bullets.points

		@dead = bullet.dead

	draw: (ctxt, alpha, offset = x:0, y:0) ->
		points = @points

		ctxt.strokeStyle = color(@color, alpha)
		ctxt.beginPath()

		x = points[0][0] - view.x + offset.x
		y = points[0][1] - view.y + offset.y
		ctxt.moveTo(x, y)

		for point in points
			x = p[0] - view.x + offset.x
			y = p[1] - view.y + offset.y
			ctxt.lineTo(x, y)

		ctxt.stroke()
