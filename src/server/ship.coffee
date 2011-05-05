ChangingObject = require './changingObject'
globals = require './server'
utils = require '../utils'
Bullet = require './bullet'
Mine = require './mine'

class Ship extends ChangingObject.ChangingObject
	constructor: (@id) ->
		super()

		@color = utils.randomColor()
		@spawn()

	spawn: () ->
		@watchChanges(
			'pos',
			'vel',
			'dir',
			'firePower',
			'cannonHeat',
			'dead',
			'exploding',
			'exploFrame' )

		@pos =
			x: Math.random() * globals.map.w
			y: Math.random() * globals.map.h
		@vel =
			x: 0
			y: 0
		@dir = Math.random() * 2*Math.PI
		@firePower = globals.minFirepower
		@cannonHeat = 0
		@dead = false
		@exploFrame = 0

		@spawn() if @collidesWithPlanet()

	move: () ->
		{x, y} = @pos

		if globals.enableShipGravity
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
		@pos.x = if @pos.x < 0 then globals.map.w else @pos.x
		@pos.x = if @pos.x > globals.map.w then 0 else @pos.x
		@pos.y = if @pos.y < 0 then globals.map.h else @pos.y
		@pos.y = if @pos.y > globals.map.h then 0 else @pos.y

		@vel.x *= globals.frictionDecay
		@vel.y *= globals.frictionDecay

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

		for p in globals.planets
			{x: px, y: py} = p.pos
			return true if utils.distance(px, py, x, y) < p.force

		return false

	collidesWithBullet: () ->
		{x, y} = @pos

		for b in globals.bullets
			if not b.dead and
					-10 < x - b.pos.x < 10 and
					-10 < y - b.pos.y < 10
				b.dead = true
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

		globals.bullets.push( new Bullet.Bullet( @, globals.bulletCount++ ))
		globals.bullets.shift() if globals.bullets.length > globals.maxBullets

		@firePower = globals.minFirepower
		@cannonHeat = globals.cannonCooldown

	dropMine: () ->
		return if @isDead() or @isExploding()

		id = globals.mineCount++
		globals.mines[id] = new Mine.Mine(@, id)

	explode : () ->
		@exploding = true
		@exploFrame = 0

	updateExplosion : () ->
		++@exploFrame

		if @exploFrame > globals.maxExploFrame
			@exploding = false
			@dead = true
			@exploFrame = 0

exports.Ship = Ship
