utils = require '../utils'
logger = require('../logger').static
ChangingObject = require('./changingObject').ChangingObject
Bullet = require('./bullet').Bullet
Shield = require('./shield').Shield

class Ship extends ChangingObject
	constructor: (@id, @game, name, color) ->
		super()

		# Send these properties to new players.
		@flagFullUpdate('type')
		@flagFullUpdate('name') if name?
		@flagFullUpdate('color')
		@flagFullUpdate('state')
		@flagFullUpdate('pos')
		@flagFullUpdate('dir')
		@flagFullUpdate('thrust')
		@flagFullUpdate('firePower')
		@flagFullUpdate('cannonHeat')
		@flagFullUpdate('boost')
		@flagFullUpdate('invisible')
		@flagFullUpdate('stats')
		if @game.prefs.debug.sendHitBoxes
			@flagFullUpdate('boundingBox')
			@flagFullUpdate('hitBox')

		@type = 'ship'
		@flagNextUpdate('type')

		# Saved name or none.
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

		# Bounding box has static radius, but follows ship.
		@boundingBox =
			radius: @game.prefs.ship.boundingBoxRadius

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

		# Set bounding box position.
		@boundingBox.x = @pos.x
		@boundingBox.y = @pos.y
		@flagNextUpdate('boundingBox') if @game.prefs.debug.sendHitBoxes

		# Initial velocity.
		@vel =
			x: 0
			y: 0

		# Initial state.
		@state = 'alive'
		@countdown = @game.prefs.ship.states[@state].countdown

		@flagNextUpdate('state')

		# Setup defaults.
		@thrust = false
		@firePower = @game.prefs.ship.minFirepower
		@cannonHeat = 0
		@ongoingTurn = 0

		@flagNextUpdate('thrust')
		@flagNextUpdate('firePower')
		@flagNextUpdate('cannonHeat')

		# Drop bonus and cancel all effects.
		@bonus = null
		@bonusTimeouts = {}
		@boost = 1
		@boostDecay = 0
		@inverseTurn = no
		@invisible = no

		# Spawn with a shield
		@game.newGameObject (id) =>
			@shield = @game.shields[id] = new Shield(id, @game, @)
			@shield.countdown = @game.prefs.ship.spawnImmunity
			@shield

		@flagNextUpdate('boost')
		@flagNextUpdate('invisible')

		@debug "spawned"

	stopTurnAccel: () ->
		@ongoingTurn = 0

	accelBezier: utils.cubicBezier(
		utils.vec.point(0, 0.07),
		utils.vec.point(1, 0.2),
		utils.vec.point(0.69, 0.1),
		utils.vec.point(0.81, 0.2))

	turnAcceleration: (turn) ->
		if @game.prefs.ship.bezierAccel
			# Map accumulated turn to [0, pi[
			turn = utils.mod(turn, Math.PI)
			# Symmetric in ]pi/2, pi]
			turn = Math.PI - turn if turn > Math.PI/2
			# Map [0, pi/2] to [0,1]
			turn /= Math.PI/2
			return @accelBezier(turn).y
		else
			return @game.prefs.ship.dirInc

	turnLeft: (step) ->
		inc = @turnAcceleration @ongoingTurn
		@ongoingTurn += inc * step
		inc = -inc if @inverseTurn
		@dir -= inc * step

		@flagNextUpdate('dir')

		@ddebug "turn left"

	turnRight: (step) ->
		inc = @turnAcceleration @ongoingTurn
		@ongoingTurn += inc * step
		inc = -inc if @inverseTurn
		@dir += inc * step

		@flagNextUpdate('dir')

		@ddebug "turn right"

	ahead: (step) ->
		@vel.x += Math.cos(@dir) * step * @game.prefs.ship.speed * @boost
		@vel.y += Math.sin(@dir) * step * @game.prefs.ship.speed * @boost
		@thrust = true

		@flagNextUpdate('thrust')

		@ddebug "thrust"

	stopEngine: () ->
		@thrust = false

		@flagNextUpdate('thrust')

		@ddebug "stop engine"

	chargeFire: (step) ->
		return if @cannonHeat > 0 or @state isnt 'alive' or @shield

		inc = @game.prefs.ship.firepowerInc * step
		@firePower = Math.min(@firePower + inc, @game.prefs.ship.maxFirepower)
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

	# Apply gravity from all planets, moons, and shields.
	gravityVector: () ->
		filter = (obj) =>
			# Only care for shields near enough, and ignore own shield.
			if obj.type is 'shield' and obj.owner isnt @
				return utils.distance(obj.pos.x, obj.pos.y, @pos.x, @pos.y) <
					@game.prefs.shield.shipAffectDistance

			if @shield and obj.type in ['planet', 'moon']
				return utils.distance(obj.pos.x, obj.pos.y, @pos.x, @pos.y) <
					obj.force + @game.prefs.shield.planetAffectDistance

			# Planet and moon gravity only if enabled.
			if @game.prefs.ship.enableGravity
				return obj.type in ['planet', 'moon']

			return false

		# Gravity factor for each object.
		force = ({object: obj}) =>
			if obj.type is 'shield'
				@game.prefs.shield.shipPush * obj.force
			else
				if @shield
					@game.prefs.shield.planetPush * obj.force
				else
					@game.prefs.ship.gravityPull * obj.force

		return @game.gravityFieldAround(@pos, filter, force)

	move: (step) ->
		return if @state in ['dead', 'ready']

		{x, y} = @pos

		# Compute new position from velocity and gravity from planets
		# and shields.
		gvec = @gravityVector()

		@vel.x += gvec.x
		@vel.y += gvec.y

		@pos.x += @vel.x
		@pos.y += @vel.y

		# Warp the ship around the map.
		utils.warp(@pos, @game.prefs.mapSize)

		@vel.x *= @game.prefs.ship.frictionDecay
		@vel.y *= @game.prefs.ship.frictionDecay

		# Update bounding box position.
		@boundingBox.x = @pos.x
		@boundingBox.y = @pos.y

		if @game.prefs.debug.sendHitBoxes
			@flagNextUpdate('boundingBox.x')
			@flagNextUpdate('boundingBox.y')

		# Only update if the change in position is noticeable.
		@flagNextUpdate('pos.x') if Math.abs(@pos.x-x) > .02
		@flagNextUpdate('pos.y') if Math.abs(@pos.y-y) > .02

		@updateHitbox()

	tangible: () ->
		@state is 'alive'

	nextState: () ->
		@state = @game.prefs.ship.states[@state].next
		@countdown = @game.prefs.ship.states[@state].countdown

		@flagNextUpdate('state')

	setState: (state) ->
		if @game.prefs.ship.states[state]?
			@flagNextUpdate('state') unless @state is state

			@state = state
			@countdown = @game.prefs.ship.states[state].countdown

	update: (step) ->
		if @countdown?
			@countdown -= @game.prefs.timestep * step
			@nextState() if @countdown <= 0

		# Process bonus effects timeouts.
		for type, effect of @bonusTimeouts
			effect.duration -= @game.prefs.timestep * step
			if effect.duration <= 0
				effect.onTimeout(@)
				delete @bonusTimeouts[type]

		switch @state
			when 'alive'
				if @cannonHeat > 0
					@cannonHeat -= @game.prefs.timestep * step
					@cannonHeat = 0 if @cannonHeat < 0

					# FIXME: client should infer this.
					@flagNextUpdate('cannonHeat')

				# Decay boost if active.
				if @boost > 1 and @boostDecay > 0
					# FIXME: longer decay in power save.
					@boost -= @boostDecay
					@boost = 1 if @boost < 1

					@flagNextUpdate('boost')

	fire : () ->
		return if @state isnt 'alive' or @cannonHeat > 0 or @shield

		bullet = @game.newGameObject (id) =>
			@ddebug "fire bullet ##{id}"
			return @game.bullets[id] = new Bullet(id, @game, @)

		@firePower = @game.prefs.ship.minFirepower
		@cannonHeat = @game.prefs.ship.cannonCooldown

		@flagNextUpdate('firePower')
		@flagNextUpdate('cannonHeat')

		@addStat('bullets fired', 1)

		# Firing cancels invisibility.
		@invisible = no

		@flagNextUpdate('invisible')

	explode : (killer) ->
		return if @state in ['dead', 'ready']

		@releaseBonus() if @bonus?

		@addStat('deaths', 1)

		# If spawned, skip alive state.
		@setState 'dead'

		@debug "exploded"

		# Transmit ship velocity and killer bullet velocity.
		@flagNextUpdate('vel')

		if killer?
			@killingAccel = killer.vel
			@flagNextUpdate('killingAccel')

	drunkEffect: () ->
		@inverseTurn = yes

		# Setup and overwrite previous drunk timeout.
		@bonusTimeouts.drunkEffect =
			duration: @game.prefs.EMP.effectDuration
			onTimeout: (ship) ->
				ship.inverseTurn = no

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
