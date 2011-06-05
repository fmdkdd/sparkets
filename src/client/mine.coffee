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

	drawMine: (ctxt) ->
		x = @pos.x
		y = @pos.y
		r = 5
		hr = @hitRadius

		if window.showHitCircles
			ctxt.strokeStyle = 'red'
			ctxt.lineWidth = 1
			strokeCircle(ctxt, x, y, hr)

		# Make the mine grow during the activation process.
		r -= r * @countdown/1000 if @state is 'inactive'

		# Draw the body of the mine.
		ctxt.fillStyle = color @color
		ctxt.save()
		ctxt.translate(x, y)
		ctxt.fillRect(-r, -r, r*2, r*2)
		ctxt.rotate(Math.PI/4)
		ctxt.fillRect(-r, -r, r*2, r*2)
		ctxt.restore()

		# Draw the sensor wave when the mine is active.
		if @state is 'active'
			ctxt.lineWidth = 3
			ctxt.strokeStyle = color(@color, 1-@hitRadius/50)
			ctxt.beginPath()
			ctxt.arc(x, y, @hitRadius, 0, 2*Math.PI, false)
			ctxt.stroke()

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
