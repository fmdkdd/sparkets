class Mine
	constructor: (mine) ->
		@state = bomb.state

		@playerId = mine.playerId
		@pos = mine.pos
		@color = mine.color
		@explosionRadius = mine.explosionRadius

		@countdown = mine.countdown
		@lastUpdate = mine.lastUpdate

	draw: (ctxt, offset) ->
		if @state == 0 or @state == 1
			@drawMine(ctxt, offset)
		else if @state == 2
			@drawExplosion(ctxt, offset)

	drawMine: (ctxt, offset) ->
		x = @pos.x + offset.x
		y = @pos.y + offset.y

		ctxt.fillStyle = color @color
		div = 10

		for i in [0...div]
			ctxt.beginPath()
			ctxt.rotate(Math.PI*0.5/div)
			ctxt.fillRect(x-15, y-15, 30, 30)
			ctxt.fill()

	drawExplosion: (ctxt, offset) ->
		x = @pos.x + offset.x
		y = @pos.y + offset.y

		ctxt.strokeStyle = color @color
		ctxt.arc(x, y, @radius, 0, 2*Math.PI, false)
		ctxt.stroke()
