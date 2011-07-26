utils = require '../utils'
ChangingObject = require('./changingObject').ChangingObject

class Tracker extends ChangingObject
	constructor: (@id, @game, @owner, @target, dropPos) ->
		super()

		@watchChanges 'type'
		@watchChanges 'pos'
		@watchChanges 'dir'
		@watchChanges 'state'
		@watchChanges 'color'
		@watchChanges 'serverDelete'
		@watchChanges 'boundingRadius'
		@watchChanges 'hitBox'

		@type = 'tracker'

		@state = 'deploying'
		@countdown = @game.prefs.tracker.states[@state].countdown

		@pos =
			x: dropPos.x
			y: dropPos.y
		@vel =
			x: 0
			y: 0
		@dir = @owner.dir

		@color = @owner.color

		@boundingRadius = @game.prefs.tracker.boundingRadius
		@hitBox =
			type: 'circle'
			radius: @boundingRadius
			x: @pos.x
			y: @pos.y

	tangible: () ->
		@state isnt 'dead'

	nextState: () ->
		@state = @game.prefs.tracker.states[@state].next
		@countdown = @game.prefs.tracker.states[@state].countdown

	setState: (state) ->
		if @game.prefs.tracker.states[state]?
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

		@vel.x += Math.cos(@dir) * @game.prefs.tracker.speed
		@vel.y += Math.sin(@dir) * @game.prefs.tracker.speed
		@pos.x += @vel.x
		@pos.y += @vel.y

		# Warp the tracker around the map.
		@warp()

		@vel.x *= @game.prefs.tracker.frictionDecay
		@vel.y *= @game.prefs.tracker.frictionDecay

		@changed 'pos'

		# Update hitbox
		@hitBox.x = @pos.x
		@hitBox.y = @pos.y
		@changed 'hitBox'

	warp: () ->
		s = @game.prefs.mapSize
		@pos.x = if @pos.x < 0 then s else @pos.x
		@pos.x = if @pos.x > s then 0 else @pos.x
		@pos.y = if @pos.y < 0 then s else @pos.y
		@pos.y = if @pos.y > s then 0 else @pos.y

	explode: () ->
		@setState 'dead'
		@serverDelete = yes

		@game.events.push
			type: 'tracker exploded'
			id: @id

exports.Tracker = Tracker
