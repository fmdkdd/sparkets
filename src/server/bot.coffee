server = require('./server')
prefs = require('./prefs')
utils = require('../utils')
Player = require('./player').Player

class Bot extends Player
	constructor: (id) ->
		super(id)

		@state = 'seek'

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
						if near(ghost, prefs.bot.acquireDistance)
							@target = p.ship
							@targetGhost = ghost
							@state = 'acquire'
							break

				@negativeGravityMove()

			# Fire at target, but do not chase yet.
			when 'acquire'
				@targetGhost = closestGhost(@target)
				if not alive(@target) or not near(@targetGhost, prefs.bot.acquireDistance)
					@state = 'seek'
					return

				@face(@targetGhost)
				@fireHard()

				# Near enough, go after it!
				if near(@targetGhost, prefs.bot.chaseDistance)
					@state = 'chase'

			# Chase, fire, kill.
			when 'chase'
				@targetGhost = closestGhost(@target)
				if not alive(@target) or not near(@targetGhost, prefs.bot.acquireDistance)
					@state = 'seek'
					return

				@face(@targetGhost)
				@ship.ahead()
				@fireHard()

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

	fireHard: () ->
		# Always fire at max power.
		if @ship.firePower < prefs.ship.maxFirepower
			@ship.chargeFire()
		else
			@ship.fire()

	negativeGravityMove: () ->
		{x, y} = @ship.pos
		ax = ay = 0

		# Try to avoid planets and mines using a negative field motion.
		for id, p of server.game.planets
			d = (p.pos.x-x)*(p.pos.x-x) + (p.pos.y-y)*(p.pos.y-y)
			d2 = -20 * p.force / (d * Math.sqrt(d))
			ax -= (x-p.pos.x) * d2
			ay -= (y-p.pos.y) * d2

		for id, p of server.game.mines
			d = (p.pos.x-x)*(p.pos.x-x) + (p.pos.y-y)*(p.pos.y-y)
			d2 = -200 / (d * Math.sqrt(d))
			ax -= (x-p.pos.x) * d2
			ay -= (y-p.pos.y) * d2

		@face({x: ax + @ship.pos.x, y: ay + @ship.pos.y})
		@ship.ahead()

exports.Bot = Bot
