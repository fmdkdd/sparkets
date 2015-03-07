utils = require('../utils')
Player = require('./player').Player

class Bot extends Player
  constructor: (id, game, persona) ->
    super(id, game)

    @initPersona(persona)

    @state = 'seek'

  initPersona: (persona) ->
    @prefs = {}

    roll = (val) ->
      if Array.isArray(val)
        if typeof val[0] is 'string'
          Array.random(val)
        else
          val[0] + (val[1] - val[0]) * Math.random()
      else
        val

    # Set default values
    for name, val of @game.prefs.bot.defaultPersona
      @prefs[name] = roll(val)

    # Override default with persona specific values
    @persona = persona
    for name, val of @game.prefs.bot[persona]
      @prefs[name] = roll(val)

    @name = @prefs.name

  update: (step) ->
    return if not @ship?

    # Automatically respawn.
    if @ship.state is 'ready'
      @state = 'seek'
      @ship.spawn()

    closestGhost = (ship) =>
      bestDistance = Infinity
      for i in [-1..1]
        for j in [-1..1]
          x = ship.pos.x + i * @game.prefs.mapSize
          y = ship.pos.y + j * @game.prefs.mapSize
          d = utils.distance(x, y, @ship.pos.x, @ship.pos.y)

          if d < bestDistance
            bestDistance = d
            bestPos = {x, y}

      return bestPos

    near = ({x, y}, dist) =>
      utils.distance(x, y, @ship.pos.x, @ship.pos.y) < dist

    allowed = (ship) ->
      ship.state is 'alive' and not ship.invisible

    fireSight = if @ship.invisible then @prefs.fireSightStealthed else @prefs.fireSight

    switch @state
      # Find a target around.
      when 'seek'
        for id, p of @game.players
          if id != @id and p.ship? and allowed(p.ship)
            ghost = closestGhost(p.ship)
            if near(ghost, @prefs.acquireDistance)
              @target = p.ship
              @targetGhost = ghost
              @state = 'acquire'
              break

        # Try to grab a bonus
        @targetBonus = null
        for id, bonus of @game.bonuses
          if near(bonus.pos, @prefs.grabBonusDistance)
            @targetBonus = bonus.pos
            break

        if @targetBonus?
          @negativeGravityMove(step, @targetBonus)
        else
          @negativeGravityMove(step)

      # Fire at target, but do not chase yet.
      when 'acquire'
        @targetGhost = closestGhost(@target)
        if not allowed(@target) or not near(@targetGhost, @prefs.acquireDistance)
          @state = 'seek'
          return

        @face(step, @targetGhost)
        @fire(step) if @inSight(@targetGhost, fireSight)

        # Near enough, go after it!
        if near(@targetGhost, @prefs.chaseDistance)
          @state = 'chase'

      # Chase, fire, kill.
      when 'chase'
        @targetGhost = closestGhost(@target)
        if not allowed(@target) or not near(@targetGhost, @prefs.acquireDistance)
          @state = 'seek'
          return

        @negativeGravityMove(step, @targetGhost)
        @fire(step) if @inSight(@targetGhost, fireSight)

    @ship.useBonus() if @ship.bonus? and @shouldUseBonus()

  shouldUseBonus: () ->
    prefName = @state + utils.capitalize(@ship.bonus.effect.type) + 'Use'
    useProbability = if @prefs[prefName]? then @prefs[prefName] else 0

    return Math.random() < useProbability

  inSight: ({x, y}, angle) ->
    targetDir = Math.atan2(y - @ship.pos.y, x - @ship.pos.x)
    targetDir = utils.relativeAngle(targetDir - @ship.dir)

    return Math.abs(targetDir) < angle

  face: (step, {x,y}) ->
    targetDir = Math.atan2(y - @ship.pos.y, x - @ship.pos.x)
    targetDir = utils.relativeAngle(targetDir - @ship.dir)

    # Bother turning?
    if Math.abs(targetDir) > @game.prefs.ship.dirInc
      # Face target
      if targetDir < 0
        @ship.turnLeft(step)
      else
        @ship.turnRight(step)

  fire: (step) ->
    # Charge before firing.
    if @ship.firePower < @prefs.firePower
      @ship.chargeFire(step)
    else
      @ship.fire()

  negativeGravityMove: (step, target) ->
    {x, y} = @ship.pos
    if target?
      ax = target.x - x
      ay = target.y - y
      norm = Math.sqrt(ax*ax + ay*ay)
      ax /= norm
      ay /= norm
    else
      ax = ay = 0

    # Get planets, moons and shields.
    filter = (obj) ->
      obj.type is 'planet' or obj.type is 'moon' or
        obj.type is 'mine' or obj.type is 'bullet'

    # Pull factor for each object.
    force = ({object: obj}) =>
      state = if @state is 'chase' then @state else 'seek'
      type = if obj.type is 'moon' then 'planet' else obj.type
      prop = state + utils.capitalize(type) + 'Avoid'
      return @prefs[prop] * obj.boundingBox.radius

    # Try to avoid planets and mines using a negative field motion.
    gvec = @game.gravityFieldAround(@ship.pos, filter, force)
    ax += gvec.x
    ay += gvec.y

    @face(step, {x: ax + x, y: ay + y})
    @ship.ahead(step)

exports.Bot = Bot
