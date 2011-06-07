class ExplosionEffect
	constructor: (@target, @speed = {x:0, y:0}) ->
		@init()

		@frame = 0
		@color = @target.color

	init: () ->
		@bits = []

		# Ensure decent fireworks.
		@speed = Math.max(@speed, 3)

		# Create explosion particles.
		for i in [0..200]
			particle =
				x: @target.pos.x
				y: @target.pos.y
				vx: .35 * @speed*(2*Math.random()-1)
				vy: .35 * @speed*(2*Math.random()-1)
				size: Math.random()*10

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
		@frame > window.maxExploFrame

	draw: (ctxt) ->
		ctxt.fillStyle = color(@color, (window.maxExploFrame-@frame)/window.maxExploFrame)
		for b in @bits
			if window.inView(b.x, b.y)
				ctxt.fillRect(b.x, b.y, b.size, b.size)

# Exports
window.ExplosionEffect = ExplosionEffect
