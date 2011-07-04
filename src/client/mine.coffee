class Mine
	constructor: (mine) ->
		@serverUpdate(mine)

	serverUpdate: (mine) ->
		for field, val of mine
			this[field] = val

	update: () ->
		@clientDelete = @serverDelete

	draw: (ctxt) ->
		if @state is 'inactive' or @state is 'active'
			@drawMine(ctxt)
		else if @state is 'exploding'
			@drawExplosion(ctxt)

	inView: (offset = {x:0, y:0}) ->
		window.boxInView(@pos.x + offset.x,
			@pos.y + offset.y, @hitRadius)

	drawHitbox: (ctxt) ->
		ctxt.strokeStyle = 'red'
		ctxt.lineWidth = 1
		strokeCircle(ctxt, @pos.x, @pos.y, @hitRadius)

	drawMine: (ctxt) ->

		# Draw the body of the mine.
		ctxt.save()
		ctxt.translate(@pos.x, @pos.y)
		scaleFactor = if @state is 'inactive' then 1 - @countdown/1000 else 1
		ctxt.scale(scaleFactor, scaleFactor)
		@drawModel(ctxt, color(@color))
		ctxt.restore()

		# Draw the sensor wave when the mine is active.
		if @state is 'active'
			ctxt.save()
			ctxt.lineWidth = 3
			ctxt.strokeStyle = color(@color, 1-@hitRadius/50)
			ctxt.translate(@pos.x, @pos.y)
			ctxt.beginPath()
			ctxt.arc(0, 0, @hitRadius, 0, 2*Math.PI, false)
			ctxt.stroke()
			ctxt.restore()

	drawModel: (ctxt, col) ->
		r = 5
		ctxt.fillStyle = col
		ctxt.fillRect(-r, -r, r*2, r*2)
		ctxt.rotate(Math.PI/4)
		ctxt.fillRect(-r, -r, r*2, r*2)

	drawExplosion: (ctxt) ->
		x = @pos.x
		y = @pos.y
		r = 80
		a = @countdown/500

		if window.showHitCircles
			ctxt.strokeStyle = 'red'
			ctxt.lineWidth = 1
			strokeCircle(ctxt, x, y, r)

		ctxt.fillStyle = color(@color, a)
		ctxt.beginPath()
		ctxt.arc(x, y, r, 0, 2*Math.PI, false)
		ctxt.fill()

# Exports
window.Mine = Mine
