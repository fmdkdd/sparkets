class SpriteManager
	constructor: () ->

	get: (type, w, h, color) ->
		@[type](w, h, color)

	'planet': (w, h, color) ->
		sprite = document.createElement('canvas')
		sprite.width = Math.ceil(w)
		sprite.height = Math.ceil(h)

		r = sprite.width/2
		ctxt = sprite.getContext('2d')
		ctxt.strokeStyle = color
		ctxt.fillStyle = 'white'
		ctxt.lineWidth = 8
		ctxt.beginPath()
		ctxt.arc(r, r, r - ctxt.lineWidth/2, 0, 2*Math.PI, false)
		ctxt.stroke()
		ctxt.fill()

		return sprite

	'mine': (w, h, color) ->
		sprite = document.createElement('canvas')
		sprite.width = Math.ceil(w)
		sprite.height = Math.ceil(h)

		r = w / Math.sqrt(2) / 2
		ctxt = sprite.getContext('2d')
		ctxt.fillStyle = color
		ctxt.save()
		ctxt.translate(sprite.width/2, sprite.height/2)
		ctxt.fillRect(-r, -r, r*2, r*2)
		ctxt.rotate(Math.PI/4)
		ctxt.fillRect(-r, -r, r*2, r*2)
		ctxt.restore()

		return sprite

# Exports
window.SpriteManager = SpriteManager
