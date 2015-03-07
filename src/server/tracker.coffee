utils = require '../utils'
ChangingObject = require('./changingObject').ChangingObject
stateMachineMixin = require('./stateMachine').mixin

class Tracker extends ChangingObject

  stateMachineMixin.call(@prototype)

  constructor: (@id, @game, @owner, @target, dropPos) ->
    super()

    # Send these properties to new players.
    @flagFullUpdate('type')
    @flagFullUpdate('ownerId')
    @flagFullUpdate('state')
    @flagFullUpdate('pos')
    @flagFullUpdate('dir')
    @flagFullUpdate('serverDelete')
    if @game.prefs.debug.sendHitBoxes
      @flagFullUpdate('boundingBox')
      @flagFullUpdate('hitBox')

    @type = 'tracker'
    @flagNextUpdate('type')

    # Transmit owner's id to clients.
    @ownerId = @owner.id
    @flagNextUpdate('ownerId')

    # Initial state.
    @setState 'deploying'
    @flagNextUpdate('state')

    # Initial position, velocity and direction.
    @pos =
      x: dropPos.x
      y: dropPos.y
    @vel =
      x: 0
      y: 0
    @flagNextUpdate('pos')
    @flagNextUpdate('dir')

    @dir = @owner.dir

    # Bounding box has static radius, following the tracker.
    radius = @game.prefs.tracker.boundingBoxRadius

    @boundingBox =
      x: @pos.x
      y: @pos.y
      radius: radius

    # Hit box is a circle with fixed radius following centered on
    # the tracker.
    @hitBox =
      type: 'circle'
      x: @pos.x
      y: @pos.y
      radius: radius

    if @game.prefs.debug.sendHitBoxes
      @flagNextUpdate('boundingBox')
      @flagNextUpdate('hitBox')

  tangible: () ->
    @state isnt 'dead'

  move: (step) ->

    return if @state isnt 'tracking'

    # Face the target.
    if @target?
      # Compute the angle to the target.
      targetPos = @game.closestGhost(@pos, @target.pos)
      dx = @pos.x - targetPos.x
      dy = @pos.y - targetPos.y
      angleToTarget = utils.relativeAngle(Math.atan2(-dy, dx) + @dir)

      # Increment the tracker angle to align it with the direction to the target.
      @dir += angleToTarget / @game.prefs.tracker.turnSpeed

    # Go forward.
    @vel.x += Math.cos(@dir) * @game.prefs.tracker.speed
    @vel.y += Math.sin(@dir) * @game.prefs.tracker.speed
    @pos.x += @vel.x
    @pos.y += @vel.y
    @flagNextUpdate('pos')
    @flagNextUpdate('dir')

    # Warp the tracker around the map.
    utils.warp(@pos, @game.prefs.mapSize)

    # Decay velocity.
    @vel.x *= @game.prefs.tracker.frictionDecay
    @vel.y *= @game.prefs.tracker.frictionDecay

    # Update bounding and hit boxes.
    @boundingBox.x = @pos.x
    @boundingBox.y = @pos.y

    @hitBox.x = @pos.x
    @hitBox.y = @pos.y

    if @game.prefs.debug.sendHitBoxes
      @flagNextUpdate('boundingBox.x')
      @flagNextUpdate('boundingBox.y')
      @flagNextUpdate('hitBox.x')
      @flagNextUpdate('hitBox.y')

  update: (step) ->

    oldState = @state

    @updateState(step)

    if @state isnt oldState
      if @state is 'tracking'
        @game.events.push
          type: 'tracker activated'
          id: @id

      else if @state is 'exploding'
        @explode()

      else if @state is 'dead'
        @serverDelete = yes
        @flagNextUpdate('serverDelete')

    # Stop tracking when the target dies.
    if @state is 'tracking' and @target?.state is 'dead'
      @target = null

  explode: () ->
    @setState 'exploding'

    @boundingBox.radius = @hitBox.radius = @game.prefs.tracker.explosionRadius

    if @game.prefs.debug.sendHitBoxes
      @flagNextUpdate('boundingBox.radius')
      @flagNextUpdate('hitBox.radius')

    @game.events.push
      type: 'tracker exploded'
      id: @id

exports.Tracker = Tracker
