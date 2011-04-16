class Bullet
	constructor: (bullet) ->
		@owner = bullet.owner

		@pos = bullet.pos
		@accel = bullet.accel
		@power = bullet.power

		@dead = bullet.dead

		@color = bullet.color
		@points = bullet.points

	draw: (ctxt, alpha, offset = {x: 0, y: 0}) ->
		ctxt.strokeStyle = color @color, alpha
		ctxt.beginPath()

		#x = @points[0][0] - view.x + offset.x
		#y = @points[0][1] - view.y + offset.y
		#ctxt.moveTo x, y

		for p in @points
			x = p[0] - view.x + offset.x
			y = p[1] - view.y + offset.y
			ctxt.lineTo x, y

		ctxt.stroke()
