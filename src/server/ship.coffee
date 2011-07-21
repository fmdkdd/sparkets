utils = require '../utils'
logger = require('../logger').static
ChangingObject = require('./changingObject').ChangingObject
Bullet = require('./bullet').Bullet

class Ship extends ChangingObject
	constructor: (@id, @game, @playerId, name, color) ->
		super()

		@watchChanges 'type'
		@watchChanges 'name'
		@watchChanges 'color'
		@watchChanges 'stats'
		@watchChanges 'state'
		@watchChanges 'countdown'
		@watchChanges 'pos'
		@watchChanges 'vel'
		@watchChanges 'dir'
		@watchChanges 'thrust'
		@watchChanges 'firePower'
		@watchChanges 'cannonHeat'
		@watchChanges 'killingAccel'
		@watchChanges 'boost'
		@watchChanges 'invisible'
		@watchChanges 'boundingRadius'
		@watchChanges 'hitBox'

		@type = 'ship'
		@name = name or null
		@color = color or utils.randomColor()

		# Session stats.
		@stats =
			kills: 0
			deaths: 0

		@boundingRadius = @game.prefs.ship.boundingRadius
		@hitBox =
			type: 'segments'
			points: [
				{x: 0, y: 0},
				{x: 0, y: 0},
				{x: 0, y: 0},
				{x: 0, y: 0}]

		@hitBoxPoints = [
			{x:  8, y:  0},
			{x: -7, y:  6},
			{x: -7, y: -6},
			{x:  8, y:  0}]

		@spawn()

	spawn: () ->
		@state = 'spawned'
		@countdown = @game.prefs.ship.states[@state].countdown

		@thrust = false
		@firePower = @game.prefs.ship.minFirepower
		@cannonHeat = 0
		@killingAccel = {x: 0, y: 0}

		# Drop bonus and cancel all effects.
		@bonus = null
		@bonusTimeout = {}
		@boost = 1
		@boostDecay = 0
		@inverseTurn = no
		@invisible = no

		@pos =
			x: Math.random() * @game.prefs.mapSize.w
			y: Math.random() * @game.prefs.mapSize.h
		@vel =
			x: 0
			y: 0
		@dir = Math.random() * 2*Math.PI

		# Update hitbox
		for i in [0...@hitBox.points.length]
			pr = utils.vec.rotate(@hitBoxPoints[i], @dir)
			@hitBox.points[i].x = @pos.x + pr.x
			@hitBox.points[i].y = @pos.y + pr.y

		@spawn() if @game.collidesWithPlanet(@)

		@emit('spawned', @)

		@debug "spawned"

	turnLeft: () ->
		@dir -= if @inverseTurn then -@game.prefs.ship.dirInc else @game.prefs.ship.dirInc
		@ddebug "turn left"

	turnRight: () ->
		@dir += if @inverseTurn then -@game.prefs.ship.dirInc else @game.prefs.ship.dirInc
		@ddebug "turn right"

	ahead: () ->
		@vel.x += Math.cos(@dir) * @game.prefs.ship.speed * @boost
		@vel.y += Math.sin(@dir) * @game.prefs.ship.speed * @boost
		@thrust = true
		@ddebug "thrust"

	chargeFire: () ->
		return if @cannonHeat > 0 or @state isnt 'alive'

		@firePower = Math.min(@firePower + @game.prefs.ship.firepowerInc, @game.prefs.ship.maxFirepower)
		@ddebug "charge fire"

	# Attach a bonus to the ship.
	holdBonus: (bonus) ->
		@releaseBonus() if @bonus?

		@bonus = bonus
		@bonus.attach(@)

	# Get rid of the bonus.
	releaseBonus: () ->
		@bonus.release()
		@bonus = null

	useBonus: () ->
		return if not @bonus? or @state isnt 'alive'

		@ddebug "use #{@bonus.type} bonus"
		@bonus.use()

	target: () ->

		# Select closest ships.
		near = {}
		for i, p of @game.players
			s = p.ship
			if s.id isnt @id and s.state is 'alive'
				shipPos = @game.closestGhost(@pos, s.pos)
				dist = utils.distance(@pos.x, @pos.y, shipPos.x, shipPos.y)

				if dist < @game.prefs.ship.maxTargetingDistance
					near[s.id] =
						distance: dist
						angle: utils.relativeAngle(Math.atan2(-(s.pos.y-@pos.y), s.pos.x-@pos.x) + @dir) * 180/Math.PI

		# Select the more "facing" ship among those lying within the
		# detection radius.
		for f in @game.prefs.ship.targetingFOVs
			inFOV = {}
			for i, s of near
				if -f < s.angle < f
					inFOV[i] = near[i]

			# Return the closest ship.
			if Object.keys(inFOV).length > 0
				bestDist = Infinity
				idBest = null
				for i, s of inFOV
					if s.distance < bestDist
						bestDist = s.distance
						idBest = i
				return @game.gameObjects[idBest]

		return null

	move: () ->
		return if @state is 'exploding' or @state is 'dead'

		{x, y} = @pos

		# With gravity enabled.
		if @game.prefs.ship.enableGravity
			{x: ax, y: ay} = @vel

			for id, p of @game.planets
				d = (p.pos.x-x)*(p.pos.x-x) + (p.pos.y-y)*(p.pos.y-y)
				d2 = 20 * p.force / (d * Math.sqrt(d))
				ax -= (x-p.pos.x) * d2
				ay -= (y-p.pos.y) * d2

			@pos.x = x + ax
			@pos.y = y + ay
			@vel.x = ax
			@vel.y = ay

		# Without gravity.
		else
			@pos.x += @vel.x
			@pos.y += @vel.y

		ax = ay = 0
		g = @game.prefs.EMP.shipPush
		for id, e of @game.EMPs
			if e.ship isnt @
				d = (e.pos.x-x)*(e.pos.x-x) + (e.pos.y-y)*(e.pos.y-y)
				d2 = g * e.force / (d * Math.sqrt(d))
				ax += (e.pos.x-x) * d2
				ay += (e.pos.y-y) * d2
		@pos.x += ax
		@pos.y += ay

		# Warp the ship around the map.
		@warp()

		@vel.x *= @game.prefs.ship.frictionDecay
		@vel.y *= @game.prefs.ship.frictionDecay

		# Only update if the change in position is noticeable.
		if Math.abs(@pos.x-x) > .05 or
				Math.abs(@pos.y-y) > .05
			@changed 'pos'
			@changed 'vel'

		# Update hitbox
		for i in [0...@hitBox.points.length]
			pr = utils.vec.rotate(@hitBoxPoints[i], @dir)
			@hitBox.points[i].x = @pos.x + pr.x
			@hitBox.points[i].y = @pos.y + pr.y
		@changed 'hitBox'

		@emit('moved', @)

	warp: () ->
		{w, h} = @game.prefs.mapSize
		@pos.x = if @pos.x < 0 then w else @pos.x
		@pos.x = if @pos.x > w then 0 else @pos.x
		@pos.y = if @pos.y < 0 then h else @pos.y
		@pos.y = if @pos.y > h then 0 else @pos.y

	tangible: () ->
		@state is 'spawned' or @state is 'alive'

	isDead: () ->
		@state is 'dead'

	isExploding: () ->
		@state is 'exploding'

	nextState: () ->
		@state = @game.prefs.ship.states[@state].next
		@countdown = @game.prefs.ship.states[@state].countdown

	update: () ->
		if @countdown?
			@countdown -= @game.prefs.timestep
			@nextState() if @countdown <= 0

		switch @state
			when 'alive'
				--@cannonHeat if @cannonHeat > 0

				@boost -= @boostDecay if @boost > 1
				@boost = 1 if @boost < 1

	fire : () ->
		return if @state isnt 'alive' or @cannonHeat > 0

		bullet = @game.newGameObject (id) =>
			@ddebug "fire bullet ##{id}"
			return @game.bullets[id] = new Bullet(@, id, @game)

		@firePower = @game.prefs.ship.minFirepower
		@cannonHeat = @game.prefs.ship.cannonCooldown

		@emit('fired', @, bullet)

	explode : () ->
		@releaseBonus() if @bonus?

		@addStat('deaths', 1)

		@game.events.push
			type: 'ship exploded'
			id: @id

		@nextState()

		@debug "exploded"

		@emit('exploded', @)

	addStat: (field, increment) ->
		@stats[field] += increment
		@changed 'stats'

	# Prefix message with ship id.
	log: (type, msg) ->
		logger.log(type, "(ship ##{@.id}) " + msg)

	error: (msg) -> @log('error', msg)
	warn: (msg) -> @log('warn', msg)
	info: (msg) -> @log('info', msg)
	debug: (msg) -> @log('debug', msg)
	ddebug: (msg) -> @log('ship', msg)


EventEmitter = require('events').EventEmitter
utils.include(Ship, EventEmitter.prototype)

exports.Ship = Ship
