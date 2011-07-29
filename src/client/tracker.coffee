class Tracker
	constructor: (@client, tracker) ->
		@serverUpdate(tracker)

		@color = @client.gameObjects[@ownerId].color

		# Create the sprite.
		s = 2*@boundingRadius + 7
		color = window.utils.color @color
		@sprite = @client.spriteManager.get('tracker', s, s, color)

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
		ctxt.drawImage(@sprite, -@sprite.width/2, -@sprite.height/2)

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
