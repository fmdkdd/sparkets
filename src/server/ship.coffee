utils = require '../utils'
logger = require('../logger').static
ChangingObject = require('./changingObject').ChangingObject
Bullet = require('./bullet').Bullet

class Ship extends ChangingObject
	constructor: (@id, @game, @playerId, name, color) ->
		super()

		# Send these properties to new players.
		@flagFullUpdate('type')
		@flagFullUpdate('name')
		@flagFullUpdate('color')
		@flagFullUpdate('state')
		@flagFullUpdate('pos')
		@flagFullUpdate('dir')
		@flagFullUpdate('thrust')
		@flagFullUpdate('firePower')
		@flagFullUpdate('cannonHeat')
		@flagFullUpdate('boost')
		@flagFullUpdate('invisible')
		@flagFullUpdate('boundingRadius')
		@flagFullUpdate('hitBox') if @game.prefs.debug.sendHitBoxes
		@flagFullUpdate('stats')

		@type = 'ship'
		@flagNextUpdate('type')

		# Saved name or none.
		if name?
			@name = name
			@flagNextUpdate('name')

		# Saved color or random one.
		@color = color or utils.randomColor()
		@flagNextUpdate('color')

		# Session stats.
		@stats =
			kills: 0
			deaths: 0

		@flagNextUpdate('stats.kills')
		@flagNextUpdate('stats.deaths')

		# Bounding radius is static.
		@boundingRadius = @game.prefs.ship.boundingRadius

		@flagNextUpdate('boundingRadius')

		# Hit box is a triangle slightly smaller than the displayed
		# ship.
		@hitBox =
			type: 'polygon'
			points: [
				{x: 0, y: 0},
				{x: 0, y: 0},
				{x: 0, y: 0}]

		@spawn()

	hitBoxPoints: [
		{x:  9, y:  0},
		{x: -10, y:  7},
		{x: -10, y: -7}]

	updateHitbox: () ->
		# Rotate hit box to ship direction.
		for i in [0...@hitBox.points.length]
			pr = utils.vec.rotate(@hitBoxPoints[i], @dir)
			@hitBox.points[i].x = @pos.x + pr.x
			@hitBox.points[i].y = @pos.y + pr.y

		@flagNextUpdate('hitBox.points') if @game.prefs.debug.sendHitBoxes

	spawn: () ->
		@pos =
			x: Math.random() * @game.prefs.mapSize
			y: Math.random() * @game.prefs.mapSize
		@dir = Math.random() * 2*Math.PI
		@updateHitbox()

		# Find a safe spawn location.
		while @game.collidesWithPlanet(@)
			@pos.x = Math.random() * @game.prefs.mapSize
			@pos.y = Math.random() * @game.prefs.mapSize
			@dir = Math.random() * 2*Math.PI
			@updateHitbox()

		@flagNextUpdate('pos')
		@flagNextUpdate('dir')

		# Initial velocity.
		@vel =
			x: 0
			y: 0

		# Initial state.
		@state = 'spawned'
		@countdown = @game.prefs.ship.states[@state].countdown

		@flagNextUpdate('state')

		# Setup defaults.
		@thrust = false
		@firePower = @game.prefs.ship.minFirepower
		@cannonHeat = 0

		@flagNextUpdate('thrust')
		@flagNextUpdate('firePower')
		@flagNextUpdate('cannonHeat')

		# Drop bonus and cancel all effects.
		@bonus = null
		@bonusTimeout = {}
		@boost = 1
		@boostDecay = 0
		@inverseTurn = no
		@invisible = no

		@flagNextUpdate('boost')
		@flagNextUpdate('invisible')

		@debug "spawned"

	turnLeft: () ->
		@dir -= if @inverseTurn then -@game.prefs.ship.dirInc else @game.prefs.ship.dirInc

		@flagNextUpdate('dir')

		@ddebug "turn left"

	turnRight: () ->
		@dir += if @inverseTurn then -@game.prefs.ship.dirInc else @game.prefs.ship.dirInc

		@flagNextUpdate('dir')

		@ddebug "turn right"

	ahead: () ->
		@vel.x += Math.cos(@dir) * @game.prefs.ship.speed * @boost
		@vel.y += Math.sin(@dir) * @game.prefs.ship.speed * @boost
		@thrust = true

		@flagNextUpdate('thrust')

		@ddebug "thrust"

	chargeFire: () ->
		return if @cannonHeat > 0 or @state isnt 'alive'

		@firePower = Math.min(@firePower + @game.prefs.ship.firepowerInc, @game.prefs.ship.maxFirepower)
		@flagNextUpdate('firePower')

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

		@addStat("#{@bonus.type}s used", 1)

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
		# DELETEME: not fun, and should use @game.gravityVector
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

		# FIXME: should use @game.gravityVector
		ax = ay = 0
		g = @game.prefs.shield.shipPush
		for id, s of @game.shields
			if s.owner isnt @
				d = (s.pos.x-x)*(s.pos.x-x) + (s.pos.y-y)*(s.pos.y-y)
				d2 = g * s.force / (d * Math.sqrt(d))
				ax += (s.pos.x-x) * d2
				ay += (s.pos.y-y) * d2
		@pos.x += ax
		@pos.y += ay

		# Warp the ship around the map.
		@warp()

		@vel.x *= @game.prefs.ship.frictionDecay
		@vel.y *= @game.prefs.ship.frictionDecay

		# Only update if the change in position is noticeable.
		@flagNextUpdate('pos.x') if Math.abs(@pos.x-x) > .02
		@flagNextUpdate('pos.y') if Math.abs(@pos.y-y) > .02

		@updateHitbox()

	warp: () ->
		s = @game.prefs.mapSize
		@pos.x = if @pos.x < 0 then s else @pos.x
		@pos.x = if @pos.x > s then 0 else @pos.x
		@pos.y = if @pos.y < 0 then s else @pos.y
		@pos.y = if @pos.y > s then 0 else @pos.y

	tangible: () ->
		@state is 'spawned' or @state is 'alive'

	isDead: () ->
		@state is 'dead'

	isExploding: () ->
		@state is 'exploding'

	nextState: () ->
		@state = @game.prefs.ship.states[@state].next
		@countdown = @game.prefs.ship.states[@state].countdown

		@flagNextUpdate('state')

	setState: (state) ->
		if @game.prefs.ship.states[state]?
			@flagNextUpdate('state') unless @state is state

			@state = state
			@countdown = @game.prefs.ship.states[state].countdown

	update: () ->
		if @countdown?
			@countdown -= @game.prefs.timestep
			@nextState() if @countdown <= 0

		switch @state
			when 'alive'
				if @cannonHeat > 0
					--@cannonHeat

					# FIXME: client should infer this.
					@flagNextUpdate('cannonHeat')

				# Decay boost if active.
				if @boost > 1 and @boostDecay > 0
					@boost -= @boostDecay
					@boost = 1 if @boost < 1

					@flagNextUpdate('boost')

	fire : () ->
		return if @state isnt 'alive' or @cannonHeat > 0

		bullet = @game.newGameObject (id) =>
			@ddebug "fire bullet ##{id}"
			return @game.bullets[id] = new Bullet(@id, @game, @)

		@firePower = @game.prefs.ship.minFirepower
		@cannonHeat = @game.prefs.ship.cannonCooldown

		@flagNextUpdate('firePower')
		@flagNextUpdate('cannonHeat')

		@addStat('bullets fired', 1)

		# Firing cancels invisibility.
		@invisible = no

		@flagNextUpdate('invisible')

	explode : (killer) ->
		return if @isExploding() or @isDead()

		@releaseBonus() if @bonus?

		@addStat('deaths', 1)

		@game.events.push
			type: 'ship exploded'
			id: @id

		# XXX: why do we keep the exploding state? It was useful when
		# the explosion was managed by the server. Now we just the send
		# the exploded event and forget the ship on the server.

		# If spawned, skip alive state.
		@setState 'exploding'

		@debug "exploded"

		# Transmit ship velocity and killer bullet velocity.
		@flagNextUpdate('vel')

		if killer?
			@killingAccel = killer.vel
			@flagNextUpdate('killingAccel')

	addStat: (field, increment) ->
		@stats[field] += increment

		# Only transmit kills and deaths to client.
		if field is 'kills' or field is 'deaths'
			@flagNextUpdate('stats.' + field)

	# Prefix message with ship id.
	log: (type, msg) ->
		logger.log(type, "(ship ##{@.id}) " + msg)

	error: (msg) -> @log('error', msg)
	warn: (msg) -> @log('warn', msg)
	info: (msg) -> @log('info', msg)
	debug: (msg) -> @log('debug', msg)
	ddebug: (msg) -> @log('ship', msg)

exports.Ship = Ship
