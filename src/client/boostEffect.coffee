class BoostEffect
	constructor: (@object, @duration, @trailLength, @trailDensity) ->
		@init()

	init: () ->
		@shadows = []

		@start = now
		@end = @start + @duration

	update: () ->
		if Math.random() < @trailDensity
			@shadows.push
				x: @object.pos.x
				y: @object.pos.y
				dir: @object.dir

			@shadows.shift() if @shadows.length > @trailLength

	deletable: () ->
		now > @end

	inView: (offset = {x:0, y:0}) ->
		true

	draw: (ctxt, offset = {x:0, y:0}) ->
		for i in [0...@shadows.length]
			s = @shadows[i]
			ctxt.save()
			ctxt.translate(s.x, s.y)
			ctxt.rotate(s.dir)
			@object.drawModel(ctxt, color(@object.color, i/(@trailLength+3)))
			ctxt.restore()

# Exports
window.BoostEffect = BoostEffect
