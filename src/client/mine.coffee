class Mine
	constructor: (@client, mine) ->
		@serverUpdate(mine)

	serverUpdate: (mine) ->
		for field, val of mine
			this[field] = val

	update: () ->
		@clientDelete = @serverDelete

	draw: (ctxt) ->
		return if @state is 'exploding' or @state is 'dead'

		# Draw the body of the mine.
		ctxt.save()
		ctxt.translate(@pos.x, @pos.y)
		@drawModel(ctxt, utils.color(@color))
		ctxt.restore()

		# Draw the sensor wave when the mine is active.
		if @state is 'active'
			for r in [@boundingRadius...0] by -20
				ctxt.save()
				ctxt.lineWidth = 3
				ctxt.strokeStyle = utils.color(@color, 1-r/50)
				ctxt.translate(@pos.x, @pos.y)
				ctxt.beginPath()
				ctxt.arc(0, 0, r, 0, 2*Math.PI, false)
				ctxt.stroke()
				ctxt.restore()


	drawModel: (ctxt, col) ->
		r = 5
		ctxt.fillStyle = col
		ctxt.fillRect(-r, -r, r*2, r*2)
		ctxt.rotate(Math.PI/4)
		ctxt.fillRect(-r, -r, r*2, r*2)

	drawHitbox: (ctxt) ->
		ctxt.strokeStyle = 'red'
		ctxt.lineWidth = 1.1
		utils.strokeCircle(ctxt, @hitBox.x, @hitBox.y, @hitBox.radius)

	inView: (offset = {x:0, y:0}) ->
		@client.boxInView(@pos.x + offset.x, @pos.y + offset.y, @boundingRadius)

	explodingEffect: () ->
		@client.effects.push new FlashEffect(@client, @pos, 80, @color, 500)

# Exports
window.Mine = Mine
