utils = require '../utils'
logger = require './logger'
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
		@trackers = {}
		@EMPs = {}
		@bonuses = {}
		@planets = {}

		@gameObjects = {}
		@gameObjectCount = 0

		@prefs = new GamePreferences(gamePrefs)

	launch: () ->
		for p in @initPlanets()
			@newGameObject (id) =>
				p.id = id
				@planets[id] = p

		@spawnBonus()
		setInterval(( () => @spawnBonus() ), @prefs.bonus.waitTime)

		# Bind socket events
		@sockets.on 'connection', (socket) =>
			@clientConnect(socket)
			socket.on 'key down', (data) =>
				@players[data.playerId].keyDown(data.key)

			socket.on 'key up', (data) =>
				@players[data.playerId].keyUp(data.key)

			socket.on 'create ship', (data) =>
				@createShip(socket, data)

			socket.on 'prefs changed', (data) =>
				@players[data.playerId].changePrefs(data.name, data.color)

			socket.on 'disconnect', () =>
				@clientDisconnect(socket)

		# Setup space grid
		@grid =
			width: @prefs.grid.width
			height: @prefs.grid.height
			cellWidth: @prefs.mapSize.w / @prefs.grid.width
			cellHeight: @prefs.mapSize.h / @prefs.grid.height
			cells: {}

		@addBots()

		@update()

	clientConnect: (socket) ->
		id = socket.id

		# Add new player to player list.
		player = @players[id] = new Player(id, @)

		socket.emit 'connected',
			playerId: id

		@info "player #{socket.id} joined"

	createShip: (socket, data) ->
		id = data.playerId
		player = @players[id]

		# Create ship.
		@newGameObject( (id) ->
			player.createShip(id) )

		# Send game objects.
		objs = @watched(@gameObjects)
		if not utils.isEmptyObject objs
			socket.emit 'objects update',
				objects: objs

		# Good news!
		socket.emit 'ship created',
			playerId: id
			shipId: player.ship.id

	watched: (objs) ->
		allWatched = {}

		for id, obj of objs
			objWatched = obj.watched()
			if not utils.isEmptyObject objWatched
				allWatched[id] = objWatched

		return allWatched

	clientDisconnect: (socket) ->
		playerId = socket.id
		shipId = @players[playerId].ship?.id

		# Tell everyone.
		@sockets.emit 'player quits',
			playerId: playerId
			shipId : shipId

		# Purge objects belonging to client.
		@deleteObject(shipId)
		delete @players[playerId]

		@info "player #{socket.id} left"

	# Game loop
	update: () ->
		# Setup next update.
		setTimeout(( () => @update() ), @prefs.timestep)

		# Skip update if no one is connected.
		return if @noHuman()

		player.update() for id, player of @players

		@updateObjects(@gameObjects)

	placeObjectInGrid: (obj) ->
		{w: mapWidth, h: mapHeight} = @prefs.mapSize
		{x: ox, y: oy} = obj.pos
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
		halfSide = obj.hitRadius
		incr = 2 * halfSide

		# Find right increment.
		until incr < Math.min(w, h)
			incr /= 2

		# Zero hit radius: can't collide, don't insert.
		if incr > 0
			cellX = -halfSide
			while cellX <= halfSide
				cellY = -halfSide
				while cellY <= halfSide
					insert(ox + cellX, oy + cellY)
					cellY += incr
				cellX += incr

	updateObjects: (objects) ->
		# Move all objects
		@grid.cells = {}
		for id, obj of objects
			obj.move()
			@placeObjectInGrid(obj) if obj.tangible()

		# Check all collisions
		for idx, cell of @grid.cells
			for i, obj1 of cell
				for j, obj2 of cell
					o1 = obj1.object
					o2 = obj2.object
					if j > i and
							o1.tangible() and
							o2.tangible() and
							(o1.collidesWith(o2, obj2.offset) or o2.collidesWith(o1, obj1.offset))
						collisions.handle(o1, o2)

		# Record all changes.
		allChanges = {}
		for id, obj of objects
			# Let object update
			obj.update()

			# Register its changes
			changes = obj.changes()
			if not utils.isEmptyObject changes
				allChanges[id] = changes
				obj.resetChanges()

			# Delete if requested
			@deleteObject id if obj.serverDelete

		# Broadcast changes to all players.
		if not utils.isEmptyObject allChanges
			@sockets.emit 'objects update',
				objects: allChanges

	collidesWithPlanet: (obj) ->
		for id, planet of @planets
			return true if obj.collidesWith(planet)
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
			when 'tracker'
				delete @trackers[id]
			when 'planet'
				delete @planets[id]
			when 'moon'
				delete @planets[id]
			when 'EMP'
				delete @EMPs[id]

		delete @gameObjects[id]

	initPlanets: () ->
		planets = []

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

		mapW = @prefs.mapSize.w
		mapH = @prefs.mapSize.h

		# If a planet is overlapping the map, it will appear to be
		# colliding with its ghosts in drawInfinity.
		nearBorder = (x, y, r) ->
			(x - r < 0 or x + r > mapW or y - r < 0 or y + r > mapH)

		min = @prefs.planet.minForce
		marge = @prefs.planet.maxForce - min

		satAbsFMin = @prefs.planet.satelliteAbsMinForce
		satFMin = @prefs.planet.satelliteMinForce
		satFMarge = @prefs.planet.satelliteMaxForce - satFMin

		satGMin = @prefs.planet.satelliteMinGap
		satGMarge = @prefs.planet.satelliteMaxGap - satGMin

		# Spawn planets randomly.
		for [0...@prefs.planet.count]
			satellite = Math.random() < @prefs.planet.satelliteChance
			colliding = yes
			# Ensure none are colliding (no do .. while in Coffee)
			while colliding
				x = Math.random() * mapW
				y = Math.random() * mapH
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
			rock = new Planet(x, y, force)
			planets.push rock
			if satellite
				planets.push new Moon(rock, satForce, satGap, @)

		@debug "#{@prefs.planet.count} planets created"

		return planets

	# Return the closest position of 'targetPos' from 'sourcePos'.
	closestGhost: (sourcePos, targetPos) ->
		bestPos = null
		bestDistance = Infinity

		for i in [-1..1]
			for j in [-1..1]
				ox = targetPos.x + i * @prefs.mapSize.w
				oy = targetPos.y + j * @prefs.mapSize.h
				d = utils.distance(sourcePos.x, sourcePos.y, ox, oy)
				if d < bestDistance
					bestDistance = d
					bestPos = {x: ox, y: oy}

		return bestPos

	spawnBonus: (bonusType) ->
		# Do nothing when no one is connected.
		return if @noHuman()

		return false if Object.keys(@bonuses).length >= @prefs.bonus.maxCount

		@newGameObject( (id) =>
			@bonuses[id] = new Bonus(id, @, bonusType)
			@debug "spawned new #{@bonuses[id].effect.type} bonus ##{id}"
			return @bonuses[id] )

	addBots: () ->
		for i in [0...3] #@prefs.bot.count]
			botId = 'b' + i
			@players[botId] = new Bot(botId, @)
			@newGameObject( (id) =>
				@debug "bot ##{botId} joined"
				return @players[botId].createShip(id) )

	noHuman: () ->
		return Object.keys(@players).length == @prefs.bot.count

	# Prefix message with game namespace.
	log: (type, msg) ->
		logger.log(type, "(game #{@sockets.name}) " + msg)

	error: (msg) -> @log('error', msg)
	warn: (msg) -> @log('warn', msg)
	info: (msg) -> @log('info', msg)
	debug: (msg) -> @log('debug', msg)

exports.GameServer = GameServer
