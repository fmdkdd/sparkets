class BoostEffect
	constructor: (@client, @object, @length = 3, @duration = 1000) ->
		@shadows = []

		@sprite = @object.sprite

		@running = yes
		setTimeout( (() => @running = no), @duration)

	update: () ->

		# Progressively insert new shadows.
		if @shadows.length < @length
			@shadows.push
				x: 0
				y: 0
				dir: 0
				alpha: (1 - @shadows.length / @length) * 0.6

		# Update shadows.
		for i in [@shadows.length-1...0]
			@shadows[i].x = @shadows[i-1].x
			@shadows[i].y = @shadows[i-1].y
			@shadows[i].dir = @shadows[i-1].dir
		@shadows[0].x = @object.pos.x
		@shadows[0].y = @object.pos.y
		@shadows[0].dir = @object.dir

	isAlive: () ->
		@object.state in ['alive', 'spawned']

	deletable: () ->
		not @running or @object.state is 'dead'

	inView: (offset = {x:0, y:0}) ->

	draw: (ctxt) ->
		for i in [0...@shadows.length]
			s = @shadows[i]
			ctxt.save()
			ctxt.globalAlpha = s.alpha
			ctxt.translate(s.x, s.y)
			ctxt.rotate(s.dir)
			ctxt.drawImage(@sprite, -@sprite.width/2, -@sprite.height/2)
			ctxt.restore()

# Exports
window.BoostEffect = BoostEffect
