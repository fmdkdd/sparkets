class Mine
	constructor: (mine) ->
		@state = mine.state
		@pos = mine.pos
		@color = mine.color
		@radius = mine.radius
		@explosionRadius = mine.explosionRadius
		@countdown = mine.countdown

	draw: (ctxt, offset) ->
		if @state is 'inactive' or @state is 'active'
			@drawMine(ctxt, offset)
		else if @state is 'exploding'
			@drawExplosion(ctxt, offset)

	drawMine: (ctxt, offset = {x:0, y:0}) ->
		x = @pos.x - view.x + offset.x
		y = @pos.y - view.y + offset.y
		r = @radius
		div = 3

		# Make the mine grow during the activation process.
		r -= r * @countdown / 1000 if @state is 0

		ctxt.fillStyle = color @color
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
		animRatio = 1 - @countdown / 1000
		r = @explosionRadius * animRatio
		a = 1 - animRatio

		ctxt.strokeStyle = color(@color, a)
		ctxt.beginPath()
		ctxt.arc(x, y, r, 0, 2*Math.PI, false)
		ctxt.stroke()
