mixin = () ->

  @drawHitbox = (ctxt) ->

    return if not @hitBox?

    ctxt.strokeStyle = 'red'
    ctxt.lineWidth = 2

    switch @hitBox.type

      when 'circle'

        utils.strokeCircle(ctxt, @hitBox.x, @hitBox.y, @hitBox.radius)

      when 'segments', 'polygon'

        ctxt.beginPath()

        ctxt.moveTo(@hitBox.points[0].x, @hitBox.points[0].y)
        for i in [1...@hitBox.points.length]
          ctxt.lineTo(@hitBox.points[i].x, @hitBox.points[i].y)

        ctxt.closePath() if @hitBox.type is 'polygon'

        ctxt.stroke()

  @drawBoundingBox = (ctxt) ->

    return if not @boundingBox?

    ctxt.strokeStyle = 'blue'
    ctxt.lineWidth = 2.5

    r = @boundingBox.radius
    ctxt.strokeRect(@boundingBox.x - r, @boundingBox.y - r, 2*r, 2*r)

  return @

window.Boxed = mixin
