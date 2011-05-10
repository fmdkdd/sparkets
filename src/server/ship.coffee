ChangingObject = require './changingObject'
globals = require './server'
prefs = require './prefs'
utils = require '../utils'
Bullet = require './bullet'
Mine = require './mine'

class Ship extends ChangingObject.ChangingObject
	constructor: (@id) ->
		super()

		@watchChanges(
			'type',
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
		@mines = 0
		@boost = 1
		@dead = false
		@exploding = false
		@exploFrame = 0
		@collisions = []
		@killingAccel = {x: 0, y: 0}

		@spawn() if @collidesWithPlanet()

	move: () ->
		return if @isDead() or @isExploding()

		{x, y} = @pos

		if prefs.ship.enableGravity
			{x: ax, y: ay} = @vel

			for id, p of globals.planets
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

	collidesWithPlanet: () ->
		for id, planet of globals.planets
			return true if @.collidesWith(planet)
		return false

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
			@explode() if @collidedWith 'ship', 'planet', 'mine'

			# Immunity to own bullet for a set time.
			bullets = @collisions.filter( ({type, owner, points}) =>
				type is 'bullet' and
					((owner.id isnt @id) or
					(points.length > 10)) )
			if bullets.length > 0
				@explode()
				@killingAccel = bullets[0].accel

			++@mines if @collisions.some( ({type, empty}) ->
				type is 'bonus' and not empty )

			@boost -= prefs.ship.boostDecay if @boost > 1
			@boost = 1 if @boost < 1

	fire : () ->
		return if @isDead() or @isExploding() or @cannonHeat > 0

		id = globals.gameObjectCount++
		globals.gameObjects[id] = globals.bullets[id] = new Bullet.Bullet(@, id)

		@firePower = prefs.ship.minFirepower
		@cannonHeat = prefs.ship.cannonCooldown

	dropMine: () ->
		return if @isDead() or @isExploding() or @mines == 0

		id = globals.gameObjectCount++
		globals.gameObjects[id] = globals.mines[id] = new Mine.Mine(@, id)

		--@mines

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
