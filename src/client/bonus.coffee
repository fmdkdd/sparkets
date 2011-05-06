class Bonus
	constructor: (bonus) ->
		@update(bonus)

	update: (bonus) ->
		for field, val of bonus
			@[field] = val

	draw: (ctxt, offset = {x:0, y:0}) ->
		return if @state is 'dead'

		x = @pos.x + offset.x
		y = @pos.y + offset.y
		s = @modelSize
		r = 5

		if not inView(x+s, y+s) and
				not inView(x+s, y-s) and
				not inView(x-s, y+s) and
				not inView(x-s, y-s)
			return

		x -= view.x
		y -= view.y

		ctxt.fillStyle = color planetColor
		ctxt.strokeStyle = color planetColor
		ctxt.lineWidth = 2
		ctxt.save()
		ctxt.translate(x, y)
		ctxt.strokeRect(-s/2, -s/2, s, s)
		ctxt.fillRect(-r, -r, r*2, r*2)
		ctxt.rotate(Math.PI/4)
		ctxt.fillRect(-r, -r, r*2, r*2)
		ctxt.restore()
