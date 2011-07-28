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

		# The default width equals 20.
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

	'bonus': (sprite, w, h, color) ->
		ctxt = sprite.getContext('2d')
		ctxt.strokeStyle = color
		ctxt.fillStyle = 'white'
		ctxt.lineWidth = 3

		ctxt.fillRect(0, 0, sprite.width, sprite.height)
		ctxt.strokeRect(0, 0, sprite.width, sprite.height)

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

	'shield': (sprite, w, h, color) ->
		ctxt = sprite.getContext('2d')
		ctxt.strokeStyle = color
		ctxt.lineWidth = 3

		r = sprite.width/2
		ctxt.beginPath()
		ctxt.arc(r, r, r - ctxt.lineWidth/2, 0, 2*Math.PI, false)
		ctxt.stroke()

		return sprite

	'bonusTracker': (sprite, w, h, color) ->
		sprite

	'bonusMine': (sprite, w, h, color) ->
		@['mine'](sprite, w, h, color)

	'bonusBoost': (sprite, w, h, color) ->
		ctxt = sprite.getContext('2d')
		ctxt.fillStyle = color
		ctxt.lineWidth = 3

		# The default width equals 20.
		scale = sprite.width / 20

		ctxt.save()
		ctxt.scale(scale, scale)
		for i in [0..1]
			ctxt.translate(i*10, 0)
			ctxt.beginPath()
			ctxt.moveTo(0, 2)
			ctxt.lineTo(5, 10)
			ctxt.lineTo(0, 18)
			ctxt.lineTo(5, 18)
			ctxt.lineTo(10, 10)
			ctxt.lineTo(5, 2)
			ctxt.closePath()
			ctxt.fill()
		ctxt.restore()

		return sprite

	'bonusShield': (sprite, w, h, color) ->
		# Shield.
		sprite

	'bonusStealth': (sprite, w, h, color) ->
		# Eye?
		sprite

	'bonusEMP': (sprite, w, h, color) ->
		# Some king of lightning.
		sprite

# Exports
window.SpriteManager = SpriteManager
