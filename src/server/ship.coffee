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
		@exploFrame = 0

		@dirtyFields =
			pos: yes
			vel: yes
			dir: yes
			firePower: yes
			cannonHeat: yes
			dead: yes
			exploding: yes
			exploFrame: yes

		@spawn() if @collidesWithPlanet()

	move: () ->
		x = @pos.x
		y = @pos.y

		@pos.x += @vel.x
		@pos.y += @vel.y

		# Warp the ship around the map
		@pos.x = if @pos.x < 0 then map.w else @pos.x
		@pos.x = if @pos.x > map.w then 0 else @pos.x
		@pos.y = if @pos.y < 0 then map.h else @pos.y
		@pos.y = if @pos.y > map.h then 0 else @pos.y

		@vel.x *= frictionDecay
		@vel.y *= frictionDecay

		if Math.abs(@pos.x-x) > .05 or
				Math.abs(@pos.y-y) > .05
			@dirtyFields.pos = yes
			@dirtyFields.vel = yes

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
				ship.explode()
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
			if @cannonHeat > 0
				--@cannonHeat
				@dirtyFields.cannonHeat = yes
			@move()
			@explode() if @collides()

	changes: () ->
		changes = {}
		for field, isDirty of @dirtyFields
			if isDirty
				changes[field] = this[field]
				@dirtyFields[field] = no
		return changes

	fire : () ->
		return if @isDead() or @isExploding() or @cannonHeat > 0

		bullets.push new Bullet @
		bullets.shift() if bullets.length > maxBullets

		@firePower = minFirepower
		@cannonHeat = cannonCooldown

		@dirtyFields.firePower = yes
		@dirtyFields.cannonHeat = yes

	dropMine: () ->
		return if @isDead() or @isExploding()

		mines.push new Mine @

	explode : () ->
		@exploding = true
		@exploFrame = 0

		@dirtyFields.exploding = yes
		@dirtyFields.exploFrame = yes

	updateExplosion : () ->
		++@exploFrame

		if @exploFrame > maxExploFrame
			@exploding = false
			@dead = true
			@exploFrame = 0

			@dirtyFields.exploding = yes
			@dirtyFields.dead = yes

		@dirtyFields.exploFrame = yes
