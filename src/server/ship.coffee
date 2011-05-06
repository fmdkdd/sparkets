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
			'pos',
			'vel',
			'dir',
			'thrust',
			'firePower',
			'cannonHeat',
			'dead',
			'exploding',
			'exploFrame' )

		@type = 'ship'
		@color = utils.randomColor()
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
		@dead = false
		@exploFrame = 0

		@spawn() if @collidesWithPlanet()

	move: () ->
		{x, y} = @pos

		if prefs.ship.enableGravity
			{x: ax, y: ay} = @vel

			for p in globals.planets
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

	collides: () ->
		@collidesWithOtherShip() or
			@collidesWithBullet() or
			@collidesWithPlanet()

	collidesWithOtherShip: () ->
		for id, ship of globals.ships
			if @id isnt ship.id and
					not ship.isDead() and
					not ship.isExploding() and
					-10 < @pos.x - ship.pos.x < 10 and
					-10 < @pos.y - ship.pos.y < 10
				ship.explode()
				return true

		return false

	collidesWithPlanet: () ->
		{x, y} = @pos

		for id, p of globals.planets
			{x: px, y: py} = p.pos
			return true if utils.distance(px, py, x, y) < p.force

		return false

	collidesWithBullet: () ->
		{x, y} = @pos

		for id, bullet of globals.bullets
			if not bullet.dead and
					-10 < x - bullet.pos.x < 10 and
					-10 < y - bullet.pos.y < 10
				bullet.dead = true
				return true

		return false

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
			@move()
			@explode() if @collides()

	fire : () ->
		return if @isDead() or @isExploding() or @cannonHeat > 0

		id = globals.gameObjectCount++
		globals.gameObjects[id] = globals.bullets[id] = new Bullet.Bullet(@, id)

		@firePower = prefs.ship.minFirepower
		@cannonHeat = prefs.ship.cannonCooldown

	dropMine: () ->
		return if @isDead() or @isExploding()

		id = globals.gameObjectCount++
		globals.gameObjects[id] = globals.mines[id] = new Mine.Mine(@, id)

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
