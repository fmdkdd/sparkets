class FlashEffect
	constructor: (@client, @pos, @radius, @color, @duration) ->
		@start = @client.now
		@end = @start + @duration

	update: () ->

	deletable: () ->
		@client.now > @end

	inView: (offset = {x:0, y:0}) ->
		@client.boxInView(@pos.x + offset.x, @pos.y + offset.y, @radius)

	draw: (ctxt, offset = {x:0, y:0}) ->
		ctxt.fillStyle = utils.color(@color, 1-(@client.now-@start)/@duration)
		ctxt.beginPath()
		ctxt.arc(@pos.x, @pos.y, @radius, 0, 2*Math.PI, false)
		ctxt.fill()


# Exports
window.FlashEffect = FlashEffect
