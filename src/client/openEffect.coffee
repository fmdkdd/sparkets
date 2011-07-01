class OpenEffect
	constructor: (@pos, @size, @color) ->
		@init()

	init: () ->
		@edges = []
		@frame = 0
		@maxOpenFrame = 70

		# Create box edges.
		positions = [[0, -@size/2], [@size/2, 0], [0, @size/2], [-@size/2, 0]]
		for i in [0..3]
			edge =
				x: @pos.x + positions[i][0]
				y: @pos.y + positions[i][1]
				r: Math.PI/2 * i
				vx: positions[i][0] * 0.1
				vy: positions[i][1] * 0.1
				vr: (Math.random()*2-1) * 0.05

			@edges.push edge

	update: () ->
		for e in @edges
			e.x += e.vx
			e.y += e.vy
			e.r += e.vr

		++@frame

	deletable: () ->
		@frame > @maxOpenFrame

	inView: (offset = {x:0, y:0}) ->
		true

	draw: (ctxt, offset = {x:0, y:0}) ->
		ctxt.strokeStyle = color(@color, (@maxOpenFrame-@frame)/@maxOpenFrame)
		ctxt.lineWidth = 2
		for e in @edges
			if window.inView(e.x + offset.x, e.y + offset.y)
				ctxt.save()
				ctxt.translate(e.x, e.y)
				ctxt.rotate(e.r)
				ctxt.beginPath()
				ctxt.moveTo(-@size/2, 0)
				ctxt.lineTo(@size/2, 0)
				ctxt.stroke()
				ctxt.restore()

# Exports
window.OpenEffect = OpenEffect
