class DislocateEffect
  constructor: (@client, @edges, @color, @duration) ->
    @start = @client.now
    @end = @start + @duration

  update: () ->
    for e in @edges
      e.x += e.vx
      e.y += e.vy
      e.r += e.vr

  deletable: () ->
    @client.now > @end

  inView: (offset = {x:0, y:0}) ->
    true

  draw: (ctxt) ->
    ctxt.strokeStyle = utils.color(@color, 1-(@client.now-@start)/@duration)
    for e in @edges
      ctxt.lineWidth = e.lineWidth or 2
      ctxt.save()
      ctxt.translate(e.x, e.y)
      ctxt.rotate(e.r)
      ctxt.beginPath()
      ctxt.moveTo(-e.size/2, 0)
      ctxt.lineTo(e.size/2, 0)
      ctxt.stroke()
      ctxt.restore()

    true

# Exports
window.DislocateEffect = DislocateEffect
