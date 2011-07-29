class BoostEffect
	constructor: (@client, @object, @length = 3, @duration = 1000) ->
		@shadows = []

		@running = yes
		setTimeout( (() => @running = no), @duration)

	newShadow: () ->
		
		# Create a new sprite.
		sprite = document.createElement('canvas')
		sprite.width = @object.sprite.width
		sprite.height = @object.sprite.height

		# Paste the object sprite and alter its opacity.
		ctxt = sprite.getContext('2d')
		ctxt.globalAlpha = (1 - @shadows.length / @length) * 0.6
		ctxt.drawImage(@object.sprite, 0, 0)
		ctxt.globalAlpha = 1

		return {sprite: sprite}

	update: () ->

		# Progressively insert new shadows.
		if @shadows.length < @length
			@shadows.push @newShadow()

		# Update shadows position.
		for i in [@shadows.length-1...0]
			@shadows[i].x = @shadows[i-1].x
			@shadows[i].y = @shadows[i-1].y
			@shadows[i].dir = @shadows[i-1].dir
		@shadows[0].x = @object.pos.x
		@shadows[0].y = @object.pos.y
		@shadows[0].dir = @object.dir

	isAlive: () ->
		@object.state isnt 'dead' and @object.state isnt 'exploding'

	deletable: () ->
		not @running or @object.state is 'dead'

	inView: (offset = {x:0, y:0}) ->
		true

	draw: (ctxt) ->
		for s in @shadows
			ctxt.save()
			ctxt.translate(s.x, s.y)
			ctxt.rotate(s.dir)
			ctxt.drawImage(s.sprite, -s.sprite.width/2, -s.sprite.height/2)
			ctxt.restore()

		true

# Exports
window.BoostEffect = BoostEffect
