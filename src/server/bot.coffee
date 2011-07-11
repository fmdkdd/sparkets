utils = require('../utils')
Player = require('./player').Player

class Bot extends Player
	constructor: (id, game, persona) ->
		super(id, game)

		@initPersona(persona)

		@state = 'seek'

	initPersona: (persona) ->
		@prefs = {}

		roll = (val) ->
			if Array.isArray(val)
				val[0] + (val[1] - val[0]) * Math.random()
			else
				val

		# Set default values
		for name, val of @game.prefs.bot.defaultPersona
			@prefs[name] = roll(val)

		# Override default with persona specific values
		@persona = persona
		for name, val of @game.prefs.bot[persona]
			@prefs[name] = roll(val)

		@name = @prefs.name

	update: () ->
		return if not @ship?

		# Automatically respawn.
		if @ship.isDead() and not @ship.isExploding()
			@state = 'seek'
			@ship.spawn()

		closestGhost = (ship) =>
			bestDistance = Infinity
			for i in [-1..1]
				for j in [-1..1]
					x = ship.pos.x + i * @game.prefs.mapSize.w
					y = ship.pos.y + j * @game.prefs.mapSize.h
					d = utils.distance(x, y, @ship.pos.x, @ship.pos.y)

					if d < bestDistance
						bestDistance = d
						bestPos = {x, y}

			return bestPos

		near = ({x, y}, dist) =>
			utils.distance(x, y, @ship.pos.x, @ship.pos.y) < dist

		alive = (ship) ->
			not (ship.isDead() or ship.isExploding())

		switch @state
			# Find a target around.
			when 'seek'
				for id, p of @game.players
					if id != @id and p.ship? and alive(p.ship)
						ghost = closestGhost(p.ship)
						if near(ghost, @prefs.acquireDistance)
							@target = p.ship
							@targetGhost = ghost
							@state = 'acquire'
							break

				# Try to grab a bonus
				@targetBonus = null
				for id, bonus of @game.bonuses
					if near(bonus.pos, @prefs.grabBonusDistance)
						@targetBonus = bonus.pos
						break

				if @targetBonus?
					@negativeGravityMove(@targetBonus)
				else
					@negativeGravityMove()

			# Fire at target, but do not chase yet.
			when 'acquire'
				@targetGhost = closestGhost(@target)
				if not alive(@target) or not near(@targetGhost, @prefs.acquireDistance)
					@state = 'seek'
					return

				@face(@targetGhost)
				@fire() if @inSight(@targetGhost, @prefs.fireSight)

				# Near enough, go after it!
				if near(@targetGhost, @prefs.chaseDistance)
					@state = 'chase'

			# Chase, fire, kill.
			when 'chase'
				@targetGhost = closestGhost(@target)
				if not alive(@target) or not near(@targetGhost, @prefs.acquireDistance)
					@state = 'seek'
					return

				@negativeGravityMove(@targetGhost)
				@fire() if @inSight(@targetGhost, @prefs.fireSight)

		@ship.useBonus() if @ship.bonus? and @shouldUseBonus()

	shouldUseBonus: () ->
		prefName = @state + utils.capitalize(@ship.bonus.type) + 'Use'
		useProbability = if @prefs[prefName]? then @prefs[prefName] else 0
		return Math.random() < useProbability

	inSight: ({x, y}, angle) ->
		targetDir = Math.atan2(y - @ship.pos.y, x - @ship.pos.x)
		targetDir = utils.relativeAngle(targetDir - @ship.dir)

		return Math.abs(targetDir) < angle

	face: ({x,y}) ->
		targetDir = Math.atan2(y - @ship.pos.y, x - @ship.pos.x)
		targetDir = utils.relativeAngle(targetDir - @ship.dir)

		# Bother turning?
		if Math.abs(targetDir) > @game.prefs.ship.dirInc
			# Face target
			if targetDir < 0
				@ship.turnLeft()
			else
				@ship.turnRight()

	fire: () ->
		# Charge before firing.
		if @ship.firePower < @prefs.firePower
			@ship.chargeFire()
		else
			@ship.fire()

	negativeGravityMove: (target) ->
		{x, y} = @ship.pos
		if target?
			ax = target.x - x
			ay = target.y - y
			norm = Math.sqrt(ax*ax + ay*ay)
			ax /= norm
			ay /= norm
		else
			ax = ay = 0

		gravityEscape = (objs, g, source = ((obj) -> obj.pos)) ->
			gx = gy = 0
			for id, obj of objs
				point = source(obj)
				d = (point.x-x)*(point.x-x) + (point.y-y)*(point.y-y)
				d2 = g * obj.hitRadius / (d * Math.sqrt(d))
				gx -= (x-point.x) * d2
				gy -= (y-point.y) * d2
			return {x: gx, y: gy}

		# Try to avoid planets and mines using a negative field motion.
		g = if @state is 'chase' then @prefs.chasePlanetAvoid else @prefs.seekPlanetAvoid
		grav = gravityEscape(@game.planets, g)
		ax += grav.x
		ay += grav.y

		g = if @state is 'chase' then @prefs.chaseMineAvoid else @prefs.seekMineAvoid
		grav = gravityEscape(@game.mines, g)
		ax += grav.x
		ay += grav.y

		g = if @state is 'chase' then @prefs.chaseBulletAvoid else @prefs.seekBulletAvoid
		grav = gravityEscape(@game.bullets, g, ((bullet) ->
			p = bullet.points[bullet.points.length-1]
			{x: p[0], y: p[1]}))
		ax += grav.x
		ay += grav.y

		@face({x: ax + x, y: ay + y})
		@ship.ahead()

exports.Bot = Bot
