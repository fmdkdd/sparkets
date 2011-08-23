utils = require '../utils'
ChangingObject = require('./changingObject').ChangingObject

class MiniTracker extends ChangingObject
	constructor: (@id, @game, @tracker) ->
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

		@type = 'mini tracker'
		@flagNextUpdate('type')

		@target = @tracker.target

		# Transmit owner id to clients.
		@owner = @tracker.owner
		@ownerId = @owner.id
		@flagNextUpdate('ownerId')

		# Initial state.
		@state = 'tracking'
		@countdown = @game.prefs.miniTracker.states[@state].countdown
		@flagNextUpdate('state')

		# Initial position, velocity and direction.
		@pos =
			x: @tracker.pos.x
			y: @tracker.pos.y
		@vel =
			x: @tracker.vel.x
			y: @tracker.vel.y
		@dir = @tracker.dir + (Math.random() * Math.PI/4 - Math.PI/8)

		@flagNextUpdate('pos')
		@flagNextUpdate('dir')

		# Bounding box has static radius, following the tracker.
		radius = @game.prefs.miniTracker.boundingBoxRadius

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

	nextState: () ->
		@state = @game.prefs.miniTracker.states[@state].next
		@countdown = @game.prefs.miniTracker.states[@state].countdown

		@flagNextUpdate('state')

	setState: (state) ->
		if @game.prefs.miniTracker.states[state]?
			@flagNextUpdate('state') unless @state is state

			@state = state
			@countdown = @game.prefs.miniTracker.states[state].countdown

	update: (step) ->
		state_old = @state

		if @countdown?
			@countdown -= @game.prefs.timestep * step
			@nextState() if @countdown <= 0

		# Stop tracking when the target dies.
		if @target? and @target.state is 'dead'
			@target = null

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
			@dir += angleToTarget / @game.prefs.miniTracker.turnSpeed

		# Go forward.
		@vel.x += Math.cos(@dir) * @game.prefs.miniTracker.speed
		@vel.y += Math.sin(@dir) * @game.prefs.miniTracker.speed
		@pos.x += @vel.x
		@pos.y += @vel.y

		@flagNextUpdate('pos')
		@flagNextUpdate('dir')

		# Warp the tracker around the map.
		utils.warp(@pos, @game.prefs.mapSize)

		# Decay velocity.
		@vel.x *= @game.prefs.miniTracker.frictionDecay
		@vel.y *= @game.prefs.miniTracker.frictionDecay

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

	explode: () ->
		@setState 'dead'
		@serverDelete = yes

		@flagNextUpdate('serverDelete')

		@game.events.push
			type: 'tracker exploded'
			id: @id

exports.MiniTracker = MiniTracker
