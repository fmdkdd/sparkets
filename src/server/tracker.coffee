utils = require '../utils'
ChangingObject = require('./changingObject').ChangingObject

class Tracker extends ChangingObject
	constructor: (@id, @game, @owner, @target, dropPos) ->
		super()

		# Send these properties to new players.
		@flagFullUpdate('type')
		@flagFullUpdate('ownerId')
		@flagFullUpdate('state')
		@flagFullUpdate('pos')
		@flagFullUpdate('dir')
		@flagFullUpdate('serverDelete')
		@flagFullUpdate('boundingRadius')
		@flagFullUpdate('hitBox') if @game.prefs.debug.sendHitBoxes

		@type = 'tracker'
		@flagNextUpdate('type')

		# Transmit owner id to clients.
		@ownerId = @owner.id
		@flagNextUpdate('ownerId')

		# Initial state.
		@state = 'deploying'
		@countdown = @game.prefs.tracker.states[@state].countdown

		@flagNextUpdate('state')

		# Initial position, velocity and direction.
		@pos =
			x: dropPos.x
			y: dropPos.y
		@vel =
			x: 0
			y: 0
		@dir = @owner.dir

		@flagNextUpdate('pos')
		@flagNextUpdate('dir')

		# Bounding radius is static.
		@boundingRadius = @game.prefs.tracker.boundingRadius

		@flagNextUpdate('boundingRadius')

		# Hit box is a circle with fixed radius following centered on
		# the tracker.
		@hitBox =
			type: 'circle'
			radius: @boundingRadius
			x: @pos.x
			y: @pos.y

		@flagNextUpdate('hitBox') if @game.prefs.debug.sendHitBoxes

	tangible: () ->
		@state isnt 'dead'

	nextState: () ->
		@state = @game.prefs.tracker.states[@state].next
		@countdown = @game.prefs.tracker.states[@state].countdown

		@flagNextUpdate('state')

	setState: (state) ->
		if @game.prefs.tracker.states[state]?
			@flagNextUpdate('state') unless @state is state

			@state = state
			@countdown = @game.prefs.tracker.states[state].countdown

	update: () ->
		state_old = @state

		if @countdown?
			@countdown -= @game.prefs.timestep
			@nextState() if @countdown <= 0

		if state_old isnt @state and @state is 'tracking'
			@game.events.push
				type: 'tracker activated'
				id: @id

		# Stop tracking when the target dies.
		if @target? and @target.state is 'dead'
			@target = null

	move: () ->
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

		# Update hitbox
		@hitBox.x = @pos.x
		@hitBox.y = @pos.y

		if @game.prefs.debug.sendHitBoxes
			@flagNextUpdate('hitBox.x')
			@flagNextUpdate('hitBox.y')

	explode: () ->
		@setState 'dead'
		@serverDelete = yes

		@flagNextUpdate('serverDelete')

		@game.events.push
			type: 'tracker exploded'
			id: @id

exports.Tracker = Tracker
