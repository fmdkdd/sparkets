class ExplosionEffect
  constructor: (@client, @pos, color, @density = 100, @bitSize = 10, @speed = 1) ->
    @init()

    # Copy color array since we will modify it.
    @color = color.slice(0)

  init: () ->
    @bits = []
    @frame = 0
    @maxExploFrame = 0

    # Ensure decent fireworks.
    @speed = Math.max(@speed, 3)

    # Create explosion particles.
    for i in [0..@density]
      particle =
        x: @pos.x
        y: @pos.y
        vx: .35 * @speed*(2*Math.random()-1)
        vy: .35 * @speed*(2*Math.random()-1)
        size: Math.random() * @bitSize

      # Circular repartition.
      angle = Math.atan2(particle.vy, particle.vx)
      particle.vx *= Math.abs(Math.cos angle)
      particle.vy *= Math.abs(Math.sin angle)

      # Particle life is proportional to size.
      # Some particles can stick longer.
      # They indicate a recent battle, and add background flavor.
      if Math.random() < .1
        particle.life = 400 - 30 * particle.size
      else
        particle.life = 50 + 2 * particle.size
      particle.lifeMax = particle.life
      @maxExploFrame = Math.max(@maxExploFrame, particle.lifeMax)

      @bits.push particle

  update: () ->
    for b in @bits
      b.x += b.vx + (-1 + 2*Math.random())/1.5
      b.y += b.vy + (-1 + 2*Math.random())/1.5
      --b.life

    # Desaturate particles after a while.
    # Less distracting.
    --@color[1] if @color[1] > 20 and @frame > 50

    ++@frame

  deletable: () ->
    @frame > @maxExploFrame

  inView: (offset = {x:0, y:0}) ->
    true

  draw: (ctxt, offset = {x:0, y:0}) ->
    ctxt.fillStyle = utils.color(@color, (@maxExploFrame-@frame)/@maxExploFrame)
    for b in @bits
      if @client.inView(b.x + offset.x, b.y + offset.y)
        if b.life > 0
          ctxt.fillStyle = utils.color(@color, b.life / (1.5 * b.lifeMax))
          ctxt.fillRect(b.x, b.y, b.size, b.size)

    true

# Exports
window.ExplosionEffect = ExplosionEffect
