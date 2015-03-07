class FlashEffect
  constructor: (@client, @pos, @radius, @color, @duration) ->
    @start = @client.now
    @end = @start + @duration

  update: () ->

  deletable: () ->
    @client.now > @end

  inView: (offset = {x:0, y:0}) ->
    @client.boxInView(@pos.x + offset.x, @pos.y + offset.y, @radius)

  animationCurve: utils.cubicBezier(
    utils.vec.point(1,0),
    utils.vec.point(0,0),
    utils.vec.point(1,1),
    utils.vec.point(0,1))

  draw: (ctxt, offset = {x:0, y:0}) ->
    t = @animationCurve((@client.now - @start) / @duration).y
    ctxt.fillStyle = utils.color(@color, t)
    ctxt.beginPath()
    ctxt.arc(@pos.x, @pos.y, @radius, 0, 2*Math.PI, false)
    ctxt.fill()

# Exports
window.FlashEffect = FlashEffect
