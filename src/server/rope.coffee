utils = require '../utils'
ChangingObject = require('./changingObject').ChangingObject

class Rope extends ChangingObject
  constructor: (@game, @id, @holder, @holdee, @ropeLength, @segments) ->
    super()

    # Send these properties to new players.
    @flagFullUpdate('type')
    @flagFullUpdate('color')
    @flagFullUpdate('serverDelete')
    @flagFullUpdate('clientChain')
    @flagFullUpdate('holderId')
    if @game.prefs.debug.sendHitBoxes
      @flagFullUpdate('boundingBox')
      @flagFullUpdate('hitBox')

    @type = 'rope'
    @flagNextUpdate('type')

    # Take color of holder, holdee, or default black.
    @color = @holder.color or @holdee.color or 'black'
    @flagNextUpdate('color')

    # Transmit holder id to clients.
    @holderId = @holder.id
    @flagNextUpdate('holderId')

    # The chain contains each object at its ends plus the articulation
    # points inbetween them.
    @segmentLength = @ropeLength / @segments
    seg =
      x: (@holdee.pos.x - @holder.pos.x) / @segments
      y: (@holdee.pos.y - @holder.pos.y) / @segments

    @chain = [@holder]
    for i in [0...@segments-1]
      @chain.push
        pos:
          x: @holder.pos.x + (i+1) * seg.x
          y: @holder.pos.y + (i+1) * seg.y
        vel:
          x: 0
          y: 0
    @chain.push @holdee

    # The client chain only contains positions from the chain.
    @updateClientChain()

    # Construct hit box with from articulation points, not counting
    # holder and holdee.
    @hitBox =
      type: 'segments'
      points: []

    for i in [1...@chain.length-1]
      @hitBox.points.push
        x: @chain[i].pos.x
        y: @chain[i].pos.y

    @flagNextUpdate('hitBox') if @game.prefs.debug.sendHitBoxes

    # Init bounding box (depends on hit box).
    @boundingBox = {}
    @updateBoundingBox()

  tangible: () ->
    yes

  move: (step) ->
    # Don't move if no object is attached.
    return if not @holder? or not @holdee?

    outside = ({x,y}) =>
      x < 0 or y < 0 or x > @game.prefs.mapSize or y > @game.prefs.mapSize

    # Update each articulation point position.
    allOutside = true
    for i in [1...@chain.length-1]
      n = @chain[i]
      n.pos.x += n.vel.x
      n.pos.y += n.vel.y

      allOutside = allOutside and outside(n.pos)

    # FIXME: sometimes when crossing corners, the holdee will
    # teleport and the hitbox will be wrong. It only lasts an
    # instant, but it is no less wrong.

    # Warp all points, or warp none.
    # Need to unwarp holdee position to check if it is outside.
    beforeLast = @chain[@chain.length-2].pos
    holdeePos = {x: @chain[@chain.length-1].pos.x, y: @chain[@chain.length-1].pos.y}
    allOutside = allOutside and
      outside(utils.unwarp(beforeLast, holdeePos, @game.prefs.mapSize))
    if allOutside
      utils.warp(node.pos, @game.prefs.mapSize) for node in @chain

    # Enforce the distance constraints.
    # Each node must pull the following one.
    for i in [0...@chain.length-1]
      curpos = @chain[i].pos
      next = @chain[i+1]
      nextpos = next.pos
      next.vel = {x:0,y:0}

      # Holder might warp, we need unwarped position to enforce
      # distance constraints or the rope will stretch hard!
      if i is 0
        curpos = {x: curpos.x, y: curpos.y}
        utils.unwarp(next.pos, curpos, @game.prefs.mapSize)

      # Holdee migth warp, same as above.
      if i is @chain.length-2
        nextpos = {x: next.pos.x, y: next.pos.y}
        utils.unwarp(curpos, nextpos, @game.prefs.mapSize)

      dist = utils.distance(curpos.x, curpos.y, nextpos.x, nextpos.y)
      if dist > @segmentLength
        ratio = (dist - @segmentLength) / dist
        next.vel.x += ratio * (curpos.x - nextpos.x)
        next.vel.y += ratio * (curpos.y - nextpos.y)

    # Update bounding box and hitbox.
    @updateHitBox()
    @updateBoundingBox()

  update: (step) ->
    # Don't send chain if no object is attached.
    return if not @holder? or not @holdee?

    @updateClientChain()

  updateClientChain: () ->
    @clientChain = []

    for n in @chain
      @clientChain.push n.pos

    @flagNextUpdate('clientChain')

  updateHitBox: () ->
    for i in [1...@chain.length-1]
      @hitBox.points[i-1].x = @chain[i].pos.x
      @hitBox.points[i-1].y = @chain[i].pos.y

    @flagNextUpdate('hitBox.points') if @game.prefs.debug.sendHitBoxes

  updateBoundingBox: () ->
    # Center on middle articulation point.
    middle = Math.floor(@hitBox.points.length/2)
    x = @boundingBox.x = @hitBox.points[middle].x
    y = @boundingBox.y = @hitBox.points[middle].y

    # XXX: max distance from middle point is incorrect, but works
    # well for our rope with distance constraints.
    maxDist = 0
    for point in @hitBox.points
      maxDist = Math.max(maxDist, utils.distance(x, y, point.x, point.y))

    @boundingBox.radius = maxDist

    @flagNextUpdate('boundingBox') if @game.prefs.debug.sendHitBoxes

  detach: () ->
    @holder = null
    @holdee = null

    @serverDelete = yes

    @flagNextUpdate('serverDelete')

    @game.events.push
      type: 'rope exploded'
      id: @id

exports.Rope = Rope
