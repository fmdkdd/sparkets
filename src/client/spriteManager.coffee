class SpriteManager
  constructor: () ->
    @cacheBlack = {}
    @cacheColored = {}

  get: (type, w, h, color) ->

    # The black version does not exist yet, draw it.
    idBlack = type+' '+w+' '+h
    if not @cacheBlack[idBlack]?

      # Create a new sprite.
      sprite = document.createElement('canvas')
      sprite.width = Math.ceil(w)
      sprite.height = Math.ceil(h)

      # Fill the sprite with a pattern.
      sprite = @draw[type](sprite, w, h)

      # Store it in the cache.
      @cacheBlack[idBlack] = sprite

    # The colored version does not exist yet, draw it.
    idColored = type+' '+w+' '+h+' '+color
    if not @cacheColored[idColored]?

      # Colorize the black version.
      sprite = @colorize(@cacheBlack[idBlack], color)

      # Store it in the cache.
      @cacheColored[idColored] = sprite

    return @cacheColored[idColored]

  colorize: (sprite, color) ->

    # Create a new sprite.
    colored = document.createElement('canvas')
    colored.width = sprite.width
    colored.height = sprite.height

    # Paste the original sprite.
    ctxt = colored.getContext('2d')
    ctxt.save()
    ctxt.drawImage(sprite, 0, 0)

    # Apply a colored overlay where the original sprite isn't transparent.
    ctxt.globalCompositeOperation = 'source-in'
    ctxt.fillStyle = color
    ctxt.fillRect(0, 0, colored.width, colored.height)
    ctxt.restore()

    return colored

  draw:
    'planet': (sprite, w, h) ->
      ctxt = sprite.getContext('2d')

      r = sprite.width/2

      # Inflate the planet sprite a little to compensate for the
      # "atmosphere" graphic effect.  Ships should not collide with
      # empty space.  Value proportional to radius, and chosen to
      # fit inside the sprite dimensions while staying true to the
      # collision radius.
      pad = r/14

      gradient = ctxt.createRadialGradient(r, r, 0, r, r, r + pad)
      gradient.addColorStop(0, 'hsla(0,0%,0%,.4)')
      gradient.addColorStop(.85, 'hsla(0,0%,0%,.3)')
      gradient.addColorStop(.9, 'hsla(0,0%,100%,.9)')
      gradient.addColorStop(.95, 'hsla(0,0%,100%,0)')
      ctxt.fillStyle = gradient

      ctxt.beginPath()
      ctxt.arc(r, r, r + pad, 0, 2*Math.PI, false)
      ctxt.fill()

      return sprite

    'ship': (sprite, w, h) ->
      ctxt = sprite.getContext('2d')
      ctxt.strokeStyle = 'black'
      ctxt.lineJoin = 'round'
      ctxt.lineWidth = 4

      # Default width is 20, default height is 14.
      points = [[-10,-7], [10,0], [-10,7], [-6,0]]
      scalex = (sprite.width-ctxt.lineWidth) / 20
      scaley = (sprite.height-ctxt.lineWidth) / 14

      ctxt.beginPath()
      ctxt.translate(sprite.width/2, sprite.height/2)
      ctxt.scale(scalex, scaley)
      for p in points
        ctxt.lineTo(p[0], p[1])
      ctxt.closePath()
      ctxt.stroke()

      return sprite

    'bonus': (sprite, w, h) ->
      ctxt = sprite.getContext('2d')
      ctxt.strokeStyle = 'black'
      ctxt.lineWidth = 3

      ctxt.strokeRect(0, 0, sprite.width, sprite.height)

      return sprite

    'mine': (sprite, w, h) ->
      ctxt = sprite.getContext('2d')
      ctxt.fillStyle = 'black'

      r = w / Math.sqrt(2) / 2
      ctxt.save()
      ctxt.translate(sprite.width/2, sprite.height/2)
      ctxt.fillRect(-r, -r, r*2, r*2)
      ctxt.rotate(Math.PI/4)
      ctxt.fillRect(-r, -r, r*2, r*2)
      ctxt.restore()

      return sprite

    'grenade': (sprite, w, h) ->
      ctxt = sprite.getContext('2d')
      ctxt.fillStyle = 'black'

      utils.strokeCircle(ctxt, w/2, h/2, w/2)

      return sprite

    'tracker': (sprite, w, h) ->
      ctxt = sprite.getContext('2d')
      ctxt.fillStyle = 'black'
      ctxt.strokeStyle = 'black'
      ctxt.lineWidth = 3

      # Default width is 50, default height is 50..
      scalex = sprite.width / 50
      scaley = sprite.height / 50

      ctxt.save()
      ctxt.scale(scalex, scaley)

      # Hull.
      ctxt.beginPath()
      ctxt.moveTo(0, 10)
      ctxt.lineTo(0, 40)
      ctxt.quadraticCurveTo(50, 40, 50, 25)
      ctxt.quadraticCurveTo(50, 10, 0, 10)
      ctxt.stroke()

      # Wings.
      ctxt.beginPath()
      ctxt.moveTo(0, 0)
      ctxt.lineTo(0, 10)
      ctxt.lineTo(25, 10)
      ctxt.fill()

      ctxt.beginPath()
      ctxt.moveTo(0, 50)
      ctxt.lineTo(0, 40)
      ctxt.lineTo(25, 40)
      ctxt.fill()

      ctxt.fillRect(0, 23, 25, 4)

      ctxt.restore()

      return sprite

    'shield': (sprite, w, h) ->
      ctxt = sprite.getContext('2d')

      ctxt.lineWidth = 6
      r = sprite.width/2

      gradient = ctxt.createRadialGradient(r, r, r - ctxt.lineWidth,
        r, r, r + ctxt.lineWidth)
      gradient.addColorStop(0, 'rgba(0,0,0,0.2)')
      gradient.addColorStop(1, 'rgba(0,0,0,0.9)')
      ctxt.strokeStyle = gradient

      ctxt.beginPath()
      ctxt.arc(r, r, r - ctxt.lineWidth/2, 0, 2*Math.PI, false)
      ctxt.stroke()

      return sprite

    'bonusMine': (sprite, w, h) ->
      @['mine'](sprite, w, h)

    'bonusGrenade': (sprite, w, h) ->
      @['grenade'](sprite, w, h)

    'bonusTracker': (sprite, w, h) ->
      ctxt = sprite.getContext('2d')
      ctxt.strokeStyle = 'black'
      ctxt.lineWidth = 2

      # Default width is 20, default height is 20.
      scalex = sprite.width / 20
      scaley = sprite.height / 20

      ctxt.save()
      ctxt.scale(scalex, scaley)
      ctxt.translate(10, 10)
      ctxt.arc(0, 0, 8, 0, 2*Math.PI, false)
      ctxt.stroke()

      for i in [0..3]
        ctxt.beginPath()
        ctxt.moveTo(10, 0)
        ctxt.lineTo(4, 0)
        ctxt.stroke()
        ctxt.rotate(Math.PI/2)

      ctxt.restore()

      return sprite

    'bonusBoost': (sprite, w, h) ->
      ctxt = sprite.getContext('2d')
      ctxt.fillStyle = 'black'

      # Default width is 20, default height is 20.
      scalex = sprite.width / 20
      scaley = sprite.height / 20

      ctxt.save()
      ctxt.scale(scalex, scaley)
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

    'bonusShield': (sprite, w, h) ->
      ctxt = sprite.getContext('2d')
      ctxt.fillStyle = 'black'

      # Default width is 100, default height is 100.
      scalex = sprite.width / 100
      scaley = sprite.height / 100

      ctxt.save()
      ctxt.scale(scalex, scaley)
      ctxt.beginPath()
      ctxt.moveTo(0, 0)
      ctxt.lineTo(10, 85)
      ctxt.lineTo(50, 100)
      ctxt.lineTo(90, 85)
      ctxt.lineTo(100, 0)
      ctxt.fill()

      ctxt.globalCompositeOperation = 'xor'
      ctxt.beginPath()
      ctxt.moveTo(50, 15)
      ctxt.lineTo(50, 85)
      ctxt.lineTo(80, 75)
      ctxt.lineTo(85, 15)
      ctxt.fill()
      ctxt.restore()

      return sprite

    'bonusStealth': (sprite, w, h) ->
      ctxt = sprite.getContext('2d')
      ctxt.fillStyle = 'black'

      # Default width is 20, default height is 20.
      scalex = sprite.width / 20
      scaley = sprite.height / 20

      ctxt.save()
      ctxt.scale(scalex, scaley)
      ctxt.beginPath()
      ctxt.moveTo(0, 10)
      ctxt.quadraticCurveTo(10, -5, 20, 10)
      ctxt.quadraticCurveTo(10, 25, 0, 10)
      ctxt.fill()

      ctxt.globalCompositeOperation = 'xor'
      ctxt.beginPath()
      ctxt.arc(10, 10, 4, 0, 2*Math.PI, false)
      ctxt.fill()
      ctxt.restore()

      return sprite

    'bonusEMP': (sprite, w, h) ->
      ctxt = sprite.getContext('2d')
      ctxt.fillStyle = 'black'

      # Default width is 20, default height is 20.
      scalex = sprite.width / 20
      scaley = sprite.height / 20

      ctxt.save()
      ctxt.scale(scalex, scaley)
      ctxt.beginPath()
      ctxt.moveTo(15, 0)
      ctxt.lineTo(0, 10)
      ctxt.lineTo(12, 10)
      ctxt.lineTo(0, 20)
      ctxt.lineTo(20, 8)
      ctxt.lineTo(8, 8)
      ctxt.fill()
      ctxt.restore()

      return sprite

# Exports
window.SpriteManager = SpriteManager
