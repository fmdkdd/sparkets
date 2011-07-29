class Tracker
	constructor: (@client, tracker) ->
		@serverUpdate(tracker)

		@color = @client.gameObjects[@ownerId].color

	serverUpdate: (tracker) ->
		utils.deepMerge(tracker, @)

	update: () ->
		@clientDelete = @serverDelete

	draw: (ctxt) ->
		return if @state is 'dead'

		ctxt.save()
		ctxt.translate(@pos.x, @pos.y)
		ctxt.rotate(@dir)
		@drawModel(ctxt, utils.color(@color))
		ctxt.restore()

	drawHitbox: (ctxt) ->
		ctxt.strokeStyle = 'red'
		ctxt.lineWidth = 1.1
		utils.strokeCircle(ctxt, @hitBox.x, @hitBox.y, @hitBox.radius)

	drawModel: (ctxt, col) ->
		hr = @boundingRadius

		ctxt.fillStyle = col
		ctxt.strokeStyle = col
		ctxt.lineWidth = 2

		ctxt.save()
		ctxt.scale(0.7, 1)

		# Draw the hull.
		ctxt.beginPath()
		ctxt.moveTo(-hr, hr)
		ctxt.lineTo(-hr, -hr)
		ctxt.quadraticCurveTo(2*hr, -hr, 3*hr, 0)
		ctxt.quadraticCurveTo(2*hr, hr, -hr, hr)
		ctxt.stroke()

		# Draw the central wing.
		ctxt.fillRect(-hr, -1, 1.5*hr, 2)

		# Draw the lateral wings.
		drawWing = (ctxt, hr) ->
			ctxt.beginPath()
			ctxt.moveTo(-hr, -hr)
			ctxt.lineTo(-hr, -2*hr)
			ctxt.lineTo(hr, -hr)
			ctxt.fill()

		drawWing(ctxt, hr)
		ctxt.scale(1, -1)
		drawWing(ctxt, hr)

		ctxt.restore()

	inView: (offset = {x:0, y:0}) ->
		@client.boxInView(@pos.x + offset.x,
			@pos.y + offset.y, @boundingRadius)

	explodingEffect: () ->
		@client.effects.push new ExplosionEffect(@client, @pos, @color, 100, 5, 0.2)

	trailEffect: () ->
		@client.effects.push new TrailEffect(@client, @, 2, 30, 3)

	boostEffect: () ->
		@client.effects.push new BoostEffect(@client, @, 3, 600)

# Exports
window.Tracker = Tracker
