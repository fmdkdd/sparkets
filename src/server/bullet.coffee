ChangingObject = require('./changingObject').ChangingObject
utils = require('../utils')

class Bullet extends ChangingObject
  constructor: (@id, @game, @owner) ->
    super()

    # Send these properties to new players.
    @flagFullUpdate('type')
    @flagFullUpdate('ownerId')
    @flagFullUpdate('lastPoint')
    @flagFullUpdate('serverDelete')
    if @game.prefs.debug.sendHitBoxes
      @flagFullUpdate('boundingBox')
      @flagFullUpdate('hitBox')

    @type = 'bullet'
    @flagNextUpdate('type')

    # Keep count of elapsed move calls since bullet emission
    # Needed to provide immunity to a ship own bullets at launch
    @elapsedMoves = 0

    # Transmit owner id to clients.
    @ownerId = @owner.id
    @flagNextUpdate('ownerId')

    # Compute initial position and velocity vector from position
    # and direction of owner ship.
    xdir = 10*Math.cos(@owner.dir)
    ydir = 10*Math.sin(@owner.dir)
    @power = @owner.firePower
    @pos =
      x: @owner.pos.x + xdir
      y: @owner.pos.y + ydir
    @vel =
      x: @owner.vel.x + @power*xdir
      y: @owner.vel.y + @power*ydir
    @flagNextUpdate('power')

    # Keep track of the last computed position to notify clients.
    @lastPoint = [@pos.x, @pos.y]
    @flagNextUpdate('lastPoint')

    # Initial hit box is a point.
    @boundingBox =
      radius: 0

    @hitBox =
      type: 'polygon'
      points: [
        {x: @pos.x, y: @pos.y},
        {x: @pos.x, y: @pos.y}]

    if @game.prefs.debug.sendHitBoxes
      @flagNextUpdate('boundingBox')
      @flagNextUpdate('hitBox')

    @state = 'active'

  # Apply gravity from all planets, moons, and shields.
  gravityVector: () ->
    # Get planets, moons and shields.
    filter = (obj) ->
      obj.type is 'planet' or obj.type is 'moon' or obj.type is 'shield'

    # Pull factor for each object.
    force = ({object: obj}) =>
      if obj.type is 'shield'
        if obj.owner is @owner
          0
        else
          @game.prefs.bullet.shieldPull * obj.force
      else
        @game.prefs.bullet.gravityPull * obj.force

    return @game.gravityFieldAround(@pos, filter, force)

  move: (step) ->
    return if @state isnt 'active'

    # Keep the starting position for hit box update.
    prevPos = {x: @pos.x, y: @pos.y}

    # Compute new position from velocity and gravity of all planets.
    gvec = @gravityVector()

    @vel.x += gvec.x
    @vel.y += gvec.y

    @pos.x += @vel.x
    @pos.y += @vel.y

    # Warp the bullet around the map.
    s = @game.prefs.mapSize
    warping = {x: 0, y: 0}
    if @pos.x < 0
      warping.x = s
    else if @pos.x > s
      warping.x = -s
    if @pos.y < 0
      warping.y = s
    else if @pos.y > s
      warping.y = -s

    if warping.x isnt 0 or warping.y isnt 0
      @pos.x += warping.x
      @pos.y += warping.y

    # Register new position for clients.
    @lastPoint = [@pos.x, @pos.y]
    @flagNextUpdate('lastPoint')

    # Update hitbox. Since collisions are relative to the bounding
    # box position (currently @pos), we need to wrap both points of
    # the hit segment.
    A =
      x: prevPos.x + warping.x
      y: prevPos.y + warping.y
    B =
      x: @pos.x
      y: @pos.y

    # Convert the last segment to a polygon for a larger hit box.
    @hitBox.points = utils.segmentToPoly(A, B, @game.prefs.bullet.hitWidth)

    # Update bounding box to cover the entire last segment.
    seg = utils.vec.minus(B, A)
    center = utils.vec.plus(A, utils.vec.times(seg, 0.5))
    @boundingBox.x = center.x
    @boundingBox.y = center.y
    @boundingBox.radius = utils.vec.length(seg)/2

    if @game.prefs.debug.sendHitBoxes
      @flagNextUpdate('boundingBox')
      @flagNextUpdate('hitBox.points')

    ++@elapsedMoves

  update: (step) ->
    switch @state

      when 'active'
        if @game.prefs.bullet.expire and @elapsedMoves > @game.prefs.bullet.expireSteps
          @state = 'dead'

      when 'dead'
        @serverDelete = yes

        @flagNextUpdate('serverDelete')

  explode: () ->
    @state = 'dead'

    @game.events.push
      type: 'bullet died'
      id: @id

  tangible: ->
    @state is 'active'

exports.Bullet = Bullet
