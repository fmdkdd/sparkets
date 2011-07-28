class SpriteManager
	constructor: () ->

	get: (type, w, h, color) ->
		@[type](w, h)

	'mine': (w, h) ->
		sprite = document.createElement('canvas')
		sprite.width = Math.ceil(w)
		sprite.height = Math.ceil(h)

		r = w / Math.sqrt(2) / 2
		ctxt = sprite.getContext('2d')
		ctxt.fillStyle = 'black'
		ctxt.save()
		ctxt.translate(sprite.width/2, sprite.height/2)
		ctxt.fillRect(-r, -r, r*2, r*2)
		ctxt.rotate(Math.PI/4)
		ctxt.fillRect(-r, -r, r*2, r*2)
		ctxt.restore()

		return sprite

# Exports
window.SpriteManager = SpriteManager
