utils = require '../utils'
logger = require('../logger').static
collisions = require('./collisions')
Bot = require('./bot').Bot
Bonus = require('./bonus').Bonus
GamePreferences = require('./prefs').GamePreferences
Moon = require('./moon').Moon
Planet = require('./planet').Planet
Player = require('./player').Player

class GameServer
	constructor: (@sockets, gamePrefs) ->
		@now = 0

		@players = {}

		@bullets = {}
		@mines = {}
		@grenades = {}
		@EMPs = {}
		@trackers = {}
		@shields = {}
		@bonuses = {}
		@planets = {}

		@gameObjects = {}
		@gameObjectCount = 0

		@events = []

		@prefs = new GamePreferences(gamePrefs)

		if @prefs.powerSave
			@prefs.timestep = 40

	launch: () ->
		@initPlanets()

		@bonusDropCountdown = 0

		# Bind socket events
		@sockets.on 'connection', (socket) =>
			@clientConnect(socket)

			socket.on 'key down', (data) =>
				@players[socket.id].keyDown(data.key)

			socket.on 'key up', (data) =>
				@players[socket.id].keyUp(data.key)

			socket.on 'create ship', (data) =>
				@createShip(socket, data)

			socket.on 'prefs changed', (data) =>
				@players[socket.id].changePrefs(data.name, data.color)

			socket.on 'message', (data) =>
				@events.push
					type: 'message'
					id: @players[socket.id].ship.id
					message: data.message

			socket.on 'disconnect', () =>
				@clientDisconnect(socket)

		# Setup space grid
		@grid =
			width: @prefs.grid.width
			height: @prefs.grid.height
			cellWidth: @prefs.mapSize / @prefs.grid.width
			cellHeight: @prefs.mapSize / @prefs.grid.height
			cells: {}

		@addBots()

		@startTime = Date.now()

		@frozen = yes
		@ended = no

	end: () ->
		# It's time! Put your pen down.
		@freeze()

		@ended = yes
		@info 'ended'

		# Notify players.
		@sockets.emit 'game end'

		# Unbind listener for this namespace in case another game with
		# the same id is created.
		@sockets.removeAllListeners('connection')

	freeze: () ->
		clearTimeout(@updateTimeout)

		@frozen = yes
		@info 'frozen'

	thaw: () ->
		@warn 'thawing but game has already ended' if @ended

		@frozen = no
		@info 'unfrozen'

		@lastUpdate = Date.now()

		@update()

	clientConnect: (socket) ->
		id = socket.id

		# Add new player to player list.
		player = @players[id] = new Player(id, @)

		msg = @sharedGamePreferences()
		socket.emit 'connected', msg

		@info "player #{socket.id} joined"

		# Human connected, update the game!
		@thaw() if @frozen

	sharedGamePreferences: () ->
		startTime: @startTime
		serverPrefs:
			mapSize: @prefs.mapSize
			duration: @prefs.duration
			ship:
				minPower: @prefs.ship.minFirepower
				maxPower: @prefs.ship.maxFirepower
				cannonCooldown: @prefs.ship.cannonCooldown
			bullet:
				hitWidth: @prefs.bullet.hitWidth
			bonus:
				boost:
					boostDuration: @prefs.bonus.boost.boostDuration
			shield:
				radius: @prefs.shield.radius

			grenade:
				radius: @prefs.grenade.radius

	createShip: (socket, data) ->
		id = socket.id
		player = @players[id]

		# Create ship.
		@newGameObject( (id) ->
			player.createShip(id) )

		# Send game objects.
		objs = @fullUpdate(@gameObjects)
		unless utils.isEmptyObject(objs)
			socket.emit 'objects update',
				objects: objs

		# Good news!
		socket.emit 'ship created',
			shipId: player.ship.id

	fullUpdate: (objs) ->
		allFull = {}

		for id, obj of objs
			objFull = obj.fullUpdateObj()
			allFull[id] = objFull unless utils.isEmptyObject(objFull)

		return allFull

	broadcastMessage: (socket, data) ->
		@sockets.emit 'player says',
			shipId: @players[socket.id].ship.id
			message: data.message

		@info "player #{socket.id} says: #{data.message}"

	clientDisconnect: (socket) ->
		playerId = socket.id
		shipId = @players[playerId].ship?.id

		# Tell everyone.
		@sockets.emit 'player quits',
			shipId : shipId

		# Purge objects belonging to client.
		ship = @gameObjects[shipId]
		if ship.shield?
			ship.shield.cancel()
		ship.explode()

		# Flag for deletion explicitely since the player has left
		ship.serverDelete = yes
		ship.flagNextUpdate('serverDelete')

		delete @players[playerId]

		@info "player #{socket.id} left"

		# Don't update the game if no one is around.
		@freeze() if @noHuman()

	# Game loop
	update: () ->
		if @frozen
			@warn 'update skipped: frozen game'
			return

		# Elapsed time since last update, relative to server timestep.
		# Factor for all discrete objet updates.
		step = (Date.now() - @lastUpdate) / @prefs.timestep

		# Setup next update.
		@updateTimeout = setTimeout(( () => @update() ), @prefs.timestep)

		# Check if a bonus drop should happen.
		@bonusDropCountdown -= @prefs.timestep * step
		if @bonusDropCountdown <= 0
			@bonusDropCountdown = @prefs.bonus.waitTime
			@spawnBonus()

		# Copy current game objects to prevent updating newly created
		# objects.
		objects = {}
		for id, obj of @gameObjects
			objects[id] = obj

		# Update players and bots.
		for id, player of @players
			player.update(step)
			# Compensate for the doubled timestep in power saving mode.
			player.update(step) if @prefs.powerSave

		# Update objects known at the update start.
		@updateObjects(objects, step)

		# Broadcast updated and new objects.
		@partialUpdate(@gameObjects)

		@lastUpdate = Date.now()

	placeObjectInGrid: (obj) ->
		mapWidth = mapHeight = @prefs.mapSize
		w = @grid.cellWidth
		h = @grid.cellHeight

		insert = (x,y) =>
			# Set offset accordingly to wrapping.
			xOff = yOff = 0
			xOff = mapWidth if x < 0
			xOff = -mapWidth if x >= mapWidth
			yOff = mapHeight if y < 0
			yOff = -mapHeight if y >= mapHeight

			gridX = Math.floor(utils.mod(x, mapWidth) / w)
			gridY = Math.floor(utils.mod(y, mapHeight) / h)
			cell = gridY * @grid.width + gridX
			@grid.cells[cell] = {} if not @grid.cells[cell]?
			gridObj = @grid.cells[cell][obj.id] = {}
			gridObj.object = obj
			gridObj.offset = {x: xOff, y: yOff}

		# Place the object in all cells containing its bounding box.
		# We go through the bounding box in increments lower than either
		# side of the box to avoid skipping a grid cell.
		x = obj.boundingBox.x
		y = obj.boundingBox.y
		halfSide = obj.boundingBox.radius
		incr = 2 * halfSide

		# Find right increment.
		until incr < Math.min(w, h)
			incr /= 2

		# Zero hit radius can't collide, don't insert.
		if incr > 0
			cellX = -halfSide
			while cellX <= halfSide
				cellY = -halfSide
				while cellY <= halfSide
					insert(x + cellX, y + cellY)
					cellY += incr
				cellX += incr

	# Return all objects in the grid cell (x,y).  `filter' can be used
	# as a predicate to filter objects.  By default, all objects are
	# accepted.
	objectsInCell: (cell, filter = (() -> yes)) ->
		# The grid leaves empty cells undefined.
		return {} if not cell?

		objs = {}
		for id, gridObj of cell
			objs[id] = gridObj if filter(gridObj.object)
		return objs

	# Return an array of all objects of the given type in neighboring
	# grid cells. Useful for gravitation field computation.
	objectsAround: ({x, y}, filter) ->
		# Return the offset for the grid cell (gridX, gridY).
		# If the grid is 10 cells wide, the cell at (-1,0) is really at
		# (9,0).  But by requesting (-1,0) instead of (9,0) we want
		# all the objects in (9,0) to behave as if they _were_ in
		# (-1,0). To do this, we need an extra offset to their position.
		gridOffset = (gridX, gridY) =>
			if gridX < 0
				xOff = -@prefs.mapSize
			else if gridX >= @grid.width
				xOff = @prefs.mapSize
			else
				xOff = 0

			if gridY < 0
				yOff = -@prefs.mapSize
			else if gridY >= @grid.height
				yOff = @prefs.mapSize
			else
				yOff = 0

			return {x: xOff, y: yOff}

		# Find the grid coordinate of the cell containing (x,y).
		gridX = Math.floor(x / @grid.cellWidth)
		gridY = Math.floor(y / @grid.cellHeight)

		# Gather objects from neighboring cells.
		objs = []
		for i in [-1..1]
			for j in [-1..1]
				# Relative, non-wrapped cell coordinates.
				gx = gridX + i
				gy = gridY + j

				# Offset to give each object in the cell.
				offset = gridOffset(gx, gy)

				# Absolute, wrapped cell coordinates.
				gx = utils.mod(gx, @grid.width)
				gy = utils.mod(gy, @grid.height)
				cell = @grid.cells[gy * @grid.width + gx]

				# Filter objects in the cell.
				cellObjs = @objectsInCell(cell, filter)

				# Add our offset. Encapsulation is necessary since we
				# don't want to polute the grid objects with our offset.
				objs.push
					objects: cellObjs
					relativeOffset: offset

		return objs

	gravityFieldAround: (pos, filter, force) ->
		# objectsAround() will return the same object for all cells it
		# appears in. We want to compute their gravity influence only
		# once! Thus we delete duplicates.
		gravityObjs = {}
		for cellObjs in @objectsAround(pos, filter)
			for id, cellObj of cellObjs.objects
				gravityObjs[id] =
					object: cellObj.object
					relativeOffset: cellObjs.relativeOffset

		# Compute object position with relative offset.
		source = (obj) ->
			x: obj.object.pos.x + obj.relativeOffset.x
			y: obj.object.pos.y + obj.relativeOffset.y

		return utils.gravityField(pos, gravityObjs, source, force)

	updateObjects: (objects, step) ->
		# Move all objects
		for id, obj of objects
			obj.move(step)
			# Compensate for the doubled timestep in power saving mode.
			obj.move(step) if @prefs.powerSave

		# Insert them into the grid for collisions.
		@grid.cells = {}
		for id, obj of objects
			@placeObjectInGrid(obj) if obj.tangible()

		# Check all collisions
		for idx, cell of @grid.cells
			for i, obj1 of cell
				for j, obj2 of cell
					o1 = obj1.object
					o2 = obj2.object
					if j > i and o1.tangible() and o2.tangible() and
							collisions.test(o1.hitBox, o2.hitBox, obj1.offset, obj2.offset)
						collisions.handle(o1, o2)

		# Let object update
		obj.update(step) for id, obj of objects

	partialUpdate: (objects) ->
		clientUpdate = {}
		for id, obj of objects
			# Grab the properties flagged for next update transmission.
			transmit = obj.nextUpdateObj()
			unless utils.isEmptyObject(transmit)
				clientUpdate[id] = transmit
				obj.unflagAllNextUpdate()

			# Delete object if requested.
			@deleteObject(id) if obj.serverDelete

		# Broadcast update and events to all players.
		unless utils.isEmptyObject(clientUpdate)
			@sockets.emit 'objects update',
				objects: clientUpdate
				events: @events

		# Clear all events
		@events = []

	collidesWithPlanet: (obj) ->
		collidesWith = (p) ->
			if p.type is 'moon'
				x2 = p.planet.pos.x
				y2 = p.planet.pos.y
				r2 = p.dist + p.force
			else
				x2 = p.pos.x
				y2 = p.pos.y
				r2 = p.force
			return (utils.distance(x, y, x2, y2) < r + r2)

		x = obj.pos.x
		y = obj.pos.y
		r = @prefs.shield.planetAffectDistance

		for id, planet of @planets
			return true if collidesWith(planet)
		return false

	newGameObject: (creator) ->
		id = @gameObjectCount++
		@gameObjects[id] = creator(id)

	deleteObject: (id) ->
		type = @gameObjects[id]?.type

		switch type
			when 'bonus'
				delete @bonuses[id]
			when 'bullet'
				delete @bullets[id]
			when 'mine'
				delete @mines[id]
			when 'grenade'
				delete @grenades[id]
			when 'EMP'
				delete @EMPs[id]
			when 'tracker'
				delete @trackers[id]
			when 'planet'
				delete @planets[id]
			when 'moon'
				delete @planets[id]
			when 'shield'
				delete @shields[id]

		delete @gameObjects[id]

	initPlanets: () ->
		add = (planet) =>
			@newGameObject (id) =>
				planet.id = id
				@planets[id] = planet

		# Circle to planet collision predicate.
		collides = (x, y, r, p) ->
			if p.type is 'moon'
				x2 = p.planet.pos.x
				y2 = p.planet.pos.y
				r2 = p.dist + p.force
			else
				x2 = p.pos.x
				y2 = p.pos.y
				r2 = p.force
			return (utils.distance(x, y, x2, y2) < r + r2)

		mapS = @prefs.mapSize

		# If a planet is overlapping the map, it will appear to be
		# colliding with its ghosts in drawInfinity.
		nearBorder = (x, y, r) ->
			(x - r < 0 or x + r > mapS or y - r < 0 or y + r > mapS)

		min = @prefs.planet.minForce
		marge = @prefs.planet.maxForce - min

		satAbsFMin = @prefs.planet.satelliteAbsMinForce
		satFMin = @prefs.planet.satelliteMinForce
		satFMarge = @prefs.planet.satelliteMaxForce - satFMin

		satGMin = @prefs.planet.satelliteMinGap
		satGMarge = @prefs.planet.satelliteMaxGap - satGMin

		# Compute the number of planets to spawn according to planet
		# density, planet force and map size.
		planetSurface = (min + marge) * (min + marge) * Math.PI
		mapSurface = mapS * mapS
		planetCount = Math.floor((mapSurface/planetSurface) * @prefs.planet.density)

		# Spawn planets randomly.
		planets = []
		for [0...planetCount]
			satellite = Math.random() < @prefs.planet.satelliteChance
			colliding = yes
			# Ensure none are colliding (no do .. while in Coffee)
			while colliding
				x = Math.random() * mapS
				y = Math.random() * mapS
				force = min + marge * Math.random()

				# Account for satellite size and distance
				if satellite
					satGap = force * (satGMin + satGMarge * Math.random())
					satForce = satAbsFMin + force * (satFMin + satFMarge * Math.random())
					totForce = force + satGap + 3*satForce
				else
					totForce = force

				# Check collisions with existing planets (and moons)
				colliding = nearBorder(x, y, totForce) or planets.some (p) ->
					collides(x, y, totForce, p)

			# Not colliding, can add it
			rock = new Planet(@, x, y, force)
			add(rock)
			planets.push(rock)
			if satellite
				moon = new Moon(@, rock, satForce, satGap)
				add(moon)
				planets.push(moon)

		@debug "#{planetCount} planets created"
		return true

	# Return the closest position of 'targetPos' from 'sourcePos'.
	closestGhost: (sourcePos, targetPos) ->
		bestPos = null
		bestDistance = Infinity

		for i in [-1..1]
			for j in [-1..1]
				ox = targetPos.x + i * @prefs.mapSize
				oy = targetPos.y + j * @prefs.mapSize
				d = utils.distance(sourcePos.x, sourcePos.y, ox, oy)
				if d < bestDistance
					bestDistance = d
					bestPos = {x: ox, y: oy}

		return bestPos

	spawnBonus: (bonusType) ->
		return false if Object.keys(@bonuses).length >= @prefs.bonus.maxCount

		@newGameObject( (id) =>
			@bonuses[id] = new Bonus(id, @, bonusType)
			@debug "spawned new #{@bonuses[id].effect.type} bonus ##{id}"
			return @bonuses[id] )

	addBots: () ->
		for i in [0...@prefs.bot.count]
			botId = 'b' + i
			@players[botId] = new Bot(botId, @)
			@newGameObject( (id) =>
				@debug "bot ##{botId} joined"
				return @players[botId].createShip(id) )

	humanCount: () ->
		Object.keys(@players).length - @prefs.bot.count

	botCount: () ->
		@prefs.bot.count

	playerCount: () ->
		Object.keys(@players).length

	noHuman: () ->
		@humanCount() is 0

	# Prefix message with game namespace.
	log: (type, msg) ->
		logger.log(type, "(game #{@sockets.name}) " + msg)

	error: (msg) -> @log('error', msg)
	warn: (msg) -> @log('warn', msg)
	info: (msg) -> @log('info', msg)
	debug: (msg) -> @log('debug', msg)

exports.GameServer = GameServer
