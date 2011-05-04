class Mine
	constructor: (mine) ->
		@state = mine.state

		@playerId = mine.playerId
		@pos = mine.pos
		@color = mine.color
		@radius = mine.radius
		@explosionRadius = mine.explosionRadius

		@countdown = mine.countdown
		@lastUpdate = mine.lastUpdate

	draw: (ctxt, offset) ->
		if @state == 0 or @state == 1
			@drawMine(ctxt, offset)
		else if @state == 2
			@drawExplosion(ctxt, offset)

	drawMine: (ctxt, offset = {x:0, y:0}) ->
		x = @pos.x - view.x + offset.x
		y = @pos.y - view.y + offset.y
		r = @radius

		ctxt.fillStyle = color @color
		div = 3

		ctxt.save()
		ctxt.translate(x, y)
		for i in [0...div]
			ctxt.beginPath()
			ctxt.rotate(Math.PI/2/div)
			ctxt.fillRect(-r, -r, r*2, r*2)
			ctxt.fill()
		ctxt.restore()

	drawExplosion: (ctxt, offset = {x:0, y:0}) ->
		x = @pos.x - view.x + offset.x
		y = @pos.y - view.y + offset.y

		ctxt.strokeStyle = color @color
		ctxt.beginPath()
		ctxt.arc(x, y, @radius, 0, 2*Math.PI, false)
		ctxt.stroke()
