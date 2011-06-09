server = require('./server')
prefs = require('./prefs')
utils = require('../utils')
Player = require('./player').Player

class Bot extends Player
	constructor: (id, persona) ->
		super(id)

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
		for name, val of prefs.bot.defaultPersona
			@prefs[name] = roll(val)

		# Override default with persona specific values
		@persona = persona
		for name, val of prefs.bot[persona]
			@prefs[name] = roll(val)

	update: () ->
		return if not @ship?

		# Automatically respawn.
		if @ship.isDead()
			@state = 'seek'
			@ship.spawn()

		closestGhost = (ship) =>
			bestDistance = Infinity
			for i in [-1..1]
				for j in [-1..1]
					x = ship.pos.x + i * prefs.server.mapSize.w
					y = ship.pos.y + j * prefs.server.mapSize.h
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
				for id, p of server.game.players
					if id != @id and p.ship? and alive(p.ship)
						ghost = closestGhost(p.ship)
						if near(ghost, @prefs.acquireDistance)
							@target = p.ship
							@targetGhost = ghost
							@state = 'acquire'
							break

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

	inSight: ({x, y}, angle) ->
		targetDir = Math.atan2(y - @ship.pos.y, x - @ship.pos.x)
		targetDir = utils.relativeAngle(targetDir - @ship.dir)

		return Math.abs(targetDir) < angle

	face: ({x,y}) ->
		targetDir = Math.atan2(y - @ship.pos.y, x - @ship.pos.x)
		targetDir = utils.relativeAngle(targetDir - @ship.dir)

		# Bother turning?
		if Math.abs(targetDir) > prefs.ship.dirInc
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

		# Try to avoid planets and mines using a negative field motion.
		g = if target? then @prefs.chasePlanetAvoid else @prefs.seekPlanetAvoid
		for id, p of server.game.planets
			d = (p.pos.x-x)*(p.pos.x-x) + (p.pos.y-y)*(p.pos.y-y)
			d2 = g * p.force / (d * Math.sqrt(d))
			ax -= (x-p.pos.x) * d2
			ay -= (y-p.pos.y) * d2

		g = if target? then @prefs.chaseMineAvoid else @prefs.seekMineAvoid
		for id, p of server.game.mines
			d = (p.pos.x-x)*(p.pos.x-x) + (p.pos.y-y)*(p.pos.y-y)
			d2 = g / (d * Math.sqrt(d))
			ax -= (x-p.pos.x) * d2
			ay -= (y-p.pos.y) * d2

		g = if target? then @prefs.chaseBulletAvoid else @prefs.seekBulletAvoid
		for id, p of server.game.bullets
			head = p.points[p.points.length-1]
			d = (head[0]-x)*(head[0]-x) + (head[1]-y)*(head[1]-y)
			d2 = g / (d * Math.sqrt(d))
			ax -= (x-head[0]) * d2
			ay -= (y-head[1]) * d2

		@face({x: ax + x, y: ay + y})
		@ship.ahead()

exports.Bot = Bot
