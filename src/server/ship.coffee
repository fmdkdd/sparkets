logger = require './logger'
prefs = require './prefs'
utils = require '../utils'
ChangingObject = require('./changingObject').ChangingObject
Bullet = require('./bullet').Bullet

class Ship extends ChangingObject
	constructor: (@id, @game, @playerId, name, color) ->
		super()

		@watchChanges(
			'type',
			'name',
			'color',
			'hitRadius',
			'pos',
			'vel',
			'dir',
			'thrust',
			'firePower',
			'cannonHeat',
			'dead',
			'exploding',
			'exploFrame',
			'killingAccel',
			'boost' )

		@type = 'ship'
		@name = if name? then name else null
		@color = if color? then color else utils.randomColor()
		@hitRadius = prefs.ship.hitRadius

		@spawn()

	spawn: () ->
		@pos =
			x: Math.random() * prefs.server.mapSize.w
			y: Math.random() * prefs.server.mapSize.h
		@vel =
			x: 0
			y: 0
		@dir = Math.random() * 2*Math.PI
		@thrust = false
		@firePower = prefs.ship.minFirepower
		@cannonHeat = 0
		@bonus = null
		@bonusTimeout = {}
		@boost = 1
		@boostDecay = 0
		@inverseTurn = no
		@dead = false
		@exploding = false
		@exploFrame = 0
		@killingAccel = {x: 0, y: 0}

		@spawn() if @game.collidesWithPlanet(@)

		@debug "spawned"

	turnLeft: () ->
		@dir -= if @inverseTurn then -prefs.ship.dirInc else prefs.ship.dirInc
		@ddebug "turn left"

	turnRight: () ->
		@dir += if @inverseTurn then -prefs.ship.dirInc else prefs.ship.dirInc
		@ddebug "turn right"

	ahead: () ->
		@vel.x += Math.cos(@dir) * prefs.ship.speed * @boost
		@vel.y += Math.sin(@dir) * prefs.ship.speed * @boost
		@thrust = true
		@ddebug "thrust"

	chargeFire: () ->
		return if @cannonHeat > 0
		@firePower = Math.min(@firePower + prefs.ship.firepowerInc, prefs.ship.maxFirepower)
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
		return if not @bonus? or @isDead() or @isExploding()

		@ddebug "use #{@bonus.type} bonus"
		@bonus.use()

	move: () ->
		return if @isDead() or @isExploding()

		{x, y} = @pos

		if prefs.ship.enableGravity
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

		else
			@pos.x += @vel.x
			@pos.y += @vel.y

		# Warp the ship around the map.
		@warp()

		@vel.x *= prefs.ship.frictionDecay
		@vel.y *= prefs.ship.frictionDecay

		if Math.abs(@pos.x-x) > .05 or
				Math.abs(@pos.y-y) > .05
			@changed 'pos'
			@changed 'vel'

	warp: () ->
		{w, h} = prefs.server.mapSize
		@pos.x = if @pos.x < 0 then w else @pos.x
		@pos.x = if @pos.x > w then 0 else @pos.x
		@pos.y = if @pos.y < 0 then h else @pos.y
		@pos.y = if @pos.y > h then 0 else @pos.y

	tangible: () ->
		not @dead and not @exploding

	collidesWith: ({pos: {x,y}, hitRadius}, offset = {x:0, y:0}) ->
		x += offset.x
		y += offset.y
		utils.distance(@pos.x, @pos.y, x, y) < @hitRadius + hitRadius

	isExploding: () ->
		@exploding

	isDead: () ->
		@dead

	update: () ->
		return if @isDead()

		if @isExploding()
			@updateExplosion()
		else
			--@cannonHeat if @cannonHeat > 0

			@boost -= @boostDecay if @boost > 1
			@boost = 1 if @boost < 1

	fire : () ->
		return if @isDead() or @isExploding() or @cannonHeat > 0

		@game.newGameObject (id) =>
			@ddebug "fire bullet ##{id}"
			return @game.bullets[id] = new Bullet(@, id, @game)

		@firePower = prefs.ship.minFirepower
		@cannonHeat = prefs.ship.cannonCooldown

	explode : () ->
		@exploding = true
		@exploFrame = 0

		@releaseBonus() if @bonus?

		@debug "explode"

	updateExplosion : () ->
		++@exploFrame

		if @exploFrame > prefs.ship.maxExploFrame
			@exploding = false
			@dead = true
			@exploFrame = 0

	# Prefix message with ship id.
	log: (type, msg) ->
		logger.log(type, "(ship ##{@.id}) " + msg)

	error: (msg) -> @log('error', msg)
	warn: (msg) -> @log('warn', msg)
	info: (msg) -> @log('info', msg)
	debug: (msg) -> @log('debug', msg)
	ddebug: (msg) -> @log('ship', msg)

exports.Ship = Ship
