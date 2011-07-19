utils = require '../utils'
ChangingObject = require('./changingObject').ChangingObject

class Tracker extends ChangingObject
	constructor: (@owner, @target, dropPos, @id, @game) ->
		super()

		@watchChanges 'type'
		@watchChanges 'pos'
		@watchChanges 'vel'
		@watchChanges 'dir'
		@watchChanges 'state'
		@watchChanges 'color'
		@watchChanges 'hitRadius'
		@watchChanges 'countdown'
		@watchChanges 'serverDelete'

		@type = 'tracker'

		@state = 'deploying'
		@countdown = @game.prefs.tracker.states[@state].countdown

		@pos = dropPos
		@vel =
			x: 0
			y: 0
		@dir = @owner.dir

		@color = @owner.color
		@hitRadius = @game.prefs.tracker.hitRadius

	tangible: () ->
		@state isnt 'dead'

	collidesWith: ({pos: {x,y}, hitRadius}) ->
		utils.distance(@pos.x, @pos.y, x, y) < @hitRadius + hitRadius

	nextState: () ->
		@state = @game.prefs.tracker.states[@state].next
		@countdown = @game.prefs.tracker.states[@state].countdown

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
		@changed 'vel'

	warp: () ->
		{w, h} = @game.prefs.mapSize
		@pos.x = if @pos.x < 0 then w else @pos.x
		@pos.x = if @pos.x > w then 0 else @pos.x
		@pos.y = if @pos.y < 0 then h else @pos.y
		@pos.y = if @pos.y > h then 0 else @pos.y

	explode: () ->
		@state = 'dead'

		@game.events.push
			type: 'tracker exploded'
			id: @id

		@serverDelete = yes

exports.Tracker = Tracker
