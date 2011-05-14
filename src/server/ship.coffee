ChangingObject = require('./changingObject').ChangingObject
server = require './server'
prefs = require './prefs'
utils = require '../utils'
Bullet = require './bullet'
Mine = require './mine'

class Ship extends ChangingObject
	constructor: (@id, @playerId) ->
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
		@name = null
		@color = utils.randomColor()
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
		@boost = 1
		@boostDecay = 0
		@dead = false
		@exploding = false
		@exploFrame = 0
		@killingAccel = {x: 0, y: 0}

		@spawn() if server.game.collidesWithPlanet(@)

	turnLeft: () ->
		@dir -= prefs.ship.dirInc

	turnRight: () ->
		@dir += prefs.ship.dirInc

	ahead: () ->
		@vel.x += Math.sin(@dir) * prefs.ship.speed * @boost
		@vel.y -= Math.cos(@dir) * prefs.ship.speed * @boost
		@thrust = true

	chargeFire: () ->
		@firePower = Math.min(@firePower + prefs.ship.firepowerInc, prefs.ship.maxFirepower)

	useBonus: () ->
		return if @isDead() or @isExploding() or not @bonus?
		@bonusTimeout = @bonus.use()

	move: () ->
		return if @isDead() or @isExploding()

		{x, y} = @pos

		if prefs.ship.enableGravity
			{x: ax, y: ay} = @vel

			for id, p of server.game.planets
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

		# Warp the ship around the map
		{w, h} = prefs.server.mapSize
		@pos.x = if @pos.x < 0 then w else @pos.x
		@pos.x = if @pos.x > w then 0 else @pos.x
		@pos.y = if @pos.y < 0 then h else @pos.y
		@pos.y = if @pos.y > h then 0 else @pos.y

		@vel.x *= prefs.ship.frictionDecay
		@vel.y *= prefs.ship.frictionDecay

		if Math.abs(@pos.x-x) > .05 or
				Math.abs(@pos.y-y) > .05
			@changed 'pos'
			@changed 'vel'

	tangible: () ->
		not @dead and not @exploding

	collidesWith: ({pos: {x,y}, hitRadius}) ->
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

		server.game.newGameObject (id) =>
			server.game.bullets[id] = new Bullet.Bullet(@, id)

		@firePower = prefs.ship.minFirepower
		@cannonHeat = prefs.ship.cannonCooldown

	explode : () ->
		@exploding = true
		@exploFrame = 0

	updateExplosion : () ->
		++@exploFrame

		if @exploFrame > prefs.ship.maxExploFrame
			@exploding = false
			@dead = true
			@exploFrame = 0

exports.Ship = Ship
