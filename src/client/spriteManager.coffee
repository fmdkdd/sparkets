class SpriteManager
	constructor: () ->

	get: (type, w, h, color) ->

		# Create a new sprite.
		sprite = document.createElement('canvas')
		sprite.width = Math.ceil(w)
		sprite.height = Math.ceil(h)

		# Fill the sprite with a pattern. 
		@[type](sprite, w, h, color)

	'planet': (sprite, w, h, color) ->
		ctxt = sprite.getContext('2d')
		ctxt.strokeStyle = color
		ctxt.fillStyle = 'white'
		ctxt.lineWidth = 8

		r = sprite.width/2
		ctxt.beginPath()
		ctxt.arc(r, r, r - ctxt.lineWidth/2, 0, 2*Math.PI, false)
		ctxt.stroke()
		ctxt.fill()

		return sprite

	'ship': (sprite, w, h, color) ->
		ctxt = sprite.getContext('2d')
		ctxt.strokeStyle = color
		ctxt.lineJoin = 'round'
		ctxt.lineWidth = 4

		# Coordinates when the width equals 20.
		points = [[-10,-7], [10,0], [-10,7], [-6,0]]
		scale = (sprite.width-ctxt.lineWidth) / 20

		ctxt.beginPath()
		ctxt.translate(sprite.width/2, sprite.height/2)
		ctxt.scale(scale, scale)
		for p in points
			ctxt.lineTo(p[0], p[1])
		ctxt.closePath()
		ctxt.stroke()

		return sprite

	'mine': (sprite, w, h, color) ->
		ctxt = sprite.getContext('2d')
		ctxt.fillStyle = color

		r = w / Math.sqrt(2) / 2
		ctxt.save()
		ctxt.translate(sprite.width/2, sprite.height/2)
		ctxt.fillRect(-r, -r, r*2, r*2)
		ctxt.rotate(Math.PI/4)
		ctxt.fillRect(-r, -r, r*2, r*2)
		ctxt.restore()

		return sprite

# Exports
window.SpriteManager = SpriteManager
