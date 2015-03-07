class ChargingEffect
  constructor: (@client, @obj, @color, @radius, @duration, @pause) ->
    @start = @client.now
    @end = @start + @duration

    # Particles are generated until @fakeEnd to create
    # a pause effect.
    @fakeEnd = @end - @pause

    @particles = []

  update: () ->

    @progress = (@client.now - @start) / (@fakeEnd - @start)

    # Instanciate new particles.
    if @progress < 1 and Math.random() < 0.1 + @progress * 0.9 # Density increases as the animation progress.
      angle = Math.random() * 2 * Math.PI
      @particles.push
        x: @radius * Math.cos(angle)
        y: @radius * Math.sin(angle)
        s: 0.99 - @progress * 0.18 # Speed increases as the animation progress.
        a: 0.1 + Math.random() * 0.5 # Opacity increases as the animation progress.
        w: 1 + Math.random() * 3 * @progress # Width increases as the animation progress.

    # Move existing particles.
    for p in @particles
      p.x *= p.s
      p.y *= p.s

    # Delete particles that reached the center.
    for i in [0...@particles]
      p = @particles[i]
      if p.x < 10 and p.y < 10
        @particles.splice(i, 1)

  deletable: () ->
    @client.now > @end and @particles.length is 0

  inView: (offset = {x:0, y:0}) ->
    true
    #@client.boxInView(@pos.x + offset.x, @pos.y + offset.y, @radius)

  draw: (ctxt, offset = {x:0, y:0}) ->

    for p in @particles
      ctxt.save()

      # Random width and opacity.
      ctxt.strokeStyle = utils.color(@color, p.a)
      ctxt.lineWidth = p.w

      ctxt.beginPath()
      ctxt.moveTo(@obj.pos.x + p.x * 1.3, @obj.pos.y  + p.y * 1.3)
      ctxt.lineTo(@obj.pos.x + p.x, @obj.pos.y + p.y)
      ctxt.stroke()

      ctxt.restore()

# Exports
window.ChargingEffect = ChargingEffect
