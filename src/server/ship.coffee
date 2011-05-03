class Ship
	constructor: (@id) ->
		@color = randomColor()
		@spawn()

	spawn: () ->
		@pos =
			x: Math.random()*map.w
			y: Math.random()*map.h
		@vel =
			x: 0
			y: 0
		@dir = Math.random() * 2*Math.PI
		@firePower = minFirepower
		@cannonHeat = 0
		@dead = false
		@exploBits = null
		@exploFrame = null

		@spawn() if @collidesWithPlanet()

	move: () ->
		@pos.x += @vel.x
		@pos.y += @vel.y

		# Warp the ship around the map
		@pos.x = if @pos.x < 0 then map.w else @pos.x
		@pos.x = if @pos.x > map.w then 0 else @pos.x
		@pos.y = if @pos.y < 0 then map.h else @pos.y
		@pos.y = if @pos.y > map.h then 0 else @pos.y

		@vel.x *= frictionDecay
		@vel.y *= frictionDecay

	collides: () ->
		@collidesWithOtherShip() or
			@collidesWithBullet() or
			@collidesWithPlanet()

	collidesWithOtherShip: () ->
		for id, ship of ships
			if @id isnt ship.id and
					not ship.isDead() and
					not ship.isExploding() and
					-10 < @pos.x - ship.pos.x < 10 and
					-10 < @pos.y - ship.pos.y < 10
				return true

		return false

	collidesWithPlanet: () ->
		x = @pos.x
		y = @pos.y

		for p in planets
			px = p.pos.x
			py = p.pos.y
			return true if distance(px, py, x, y) < p.force

		return false

	collidesWithBullet: () ->
		x = @pos.x
		y = @pos.y

		for b in bullets
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

		bullets.push new Bullet @
		bullets.shift() if bullets.length > maxBullets

		@firePower = minFirepower
		@cannonHeat = cannonCooldown

	explode : () ->
		@exploding = true
		@exploFrame = 0

	updateExplosion : () ->
		++@exploFrame

		if @exploFrame > maxExploFrame
			@exploding = false
			@dead = true
			@exploFrame = null