class DislocateEffect
	constructor: (@edges, @pos, @color, @duration) ->
		@start = now
		@end = @start + @duration

	update: () ->
		for e in @edges
			e.x += e.vx
			e.y += e.vy
			e.r += e.vr

	deletable: () ->
		now > @end

	inView: (offset = {x:0, y:0}) ->
		true

	draw: (ctxt, offset = {x:0, y:0}) ->
		ctxt.strokeStyle = color(@color, 1-(now-@start)/@duration)
		ctxt.lineWidth = 2
		for e in @edges
			ctxt.save()
			ctxt.translate(e.x, e.y)
			ctxt.rotate(e.r)
			ctxt.beginPath()
			ctxt.moveTo(-e.size/2, 0)
			ctxt.lineTo(e.size/2, 0)
			ctxt.stroke()
			ctxt.restore()

# Exports
window.DislocateEffect = DislocateEffect
