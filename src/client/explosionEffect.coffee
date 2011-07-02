class ExplosionEffect
	constructor: (@pos, @color, @density = 100, @bitSize = 10, @speed = 1) ->
		@init()

	init: () ->
		@bits = []
		@frame = 0
		@maxExploFrame = 50

		# Ensure decent fireworks.
		@speed = Math.max(@speed, 3)

		# Create explosion particles.
		for i in [0..@density]
			particle =
				x: @pos.x
				y: @pos.y
				vx: .35 * @speed*(2*Math.random()-1)
				vy: .35 * @speed*(2*Math.random()-1)
				size: Math.random() * @bitSize

			# Circular repartition.
			angle = Math.atan2(particle.vy, particle.vx)
			particle.vx *= Math.abs(Math.cos angle)
			particle.vy *= Math.abs(Math.sin angle)

			@bits.push particle

	update: () ->
		for b in @bits
			b.x += b.vx + (-1 + 2*Math.random())/1.5
			b.y += b.vy + (-1 + 2*Math.random())/1.5

		++@frame

	deletable: () ->
		@frame > @maxExploFrame

	inView: (offset = {x:0, y:0}) ->
		true

	draw: (ctxt, offset = {x:0, y:0}) ->
		ctxt.fillStyle = color(@color, (@maxExploFrame-@frame)/@maxExploFrame)
		for b in @bits
			if window.inView(b.x + offset.x, b.y + offset.y)
				ctxt.fillRect(b.x, b.y, b.size, b.size)

# Exports
window.ExplosionEffect = ExplosionEffect
