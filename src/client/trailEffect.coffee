class TrailEffect
  constructor: (@client, @object, @dispersion = 0.5, @life = 30, @size = 5) ->
    @particles = []

  update: () ->

    # Delete expired particles
    particles = []
    for p in @particles
      if p.life > 0
        particles.push p
    @particles = particles

    # Update existing particles.
    for p in @particles
      p.x += p.vx
      p.y += p.vy
      p.vx *= 0.9
      p.vy *= 0.9
      --p.life

    # Add a new particle.
    if @object.state isnt 'dead'
      ejectionDir = (@object.dir + Math.PI) + (Math.random() * 2 * @dispersion - @dispersion)
      @particles.push
        x: @object.pos.x
        y: @object.pos.y
        vx: 2 * Math.cos(ejectionDir + Math.random() * @dispersion)
        vy: 2 * Math.sin(ejectionDir + Math.random() * 0.2)
        life: @life

  deletable: () ->
    @object.state is 'dead' and @particles.length is 0

  inView: (offset = {x:0, y:0}) ->
    true

  draw: (ctxt, offset = {x:0, y:0}) ->
    for p in @particles
      ctxt.fillStyle = utils.color(@object.color, p.life/@life)
      ctxt.save()
      ctxt.translate(p.x, p.y)
      ctxt.scale(@size, @size)
      ctxt.fillRect(-0.5, -0.5, 1, 1)
      ctxt.restore()

    true

# Exports
window.TrailEffect = TrailEffect
