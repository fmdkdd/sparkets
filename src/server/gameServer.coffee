prefs = require './prefs'
Player = require('./player').Player
Bonus = require('./bonus').Bonus
Planet = require('./planet').Planet
Moon = require('./moon').Moon
collisions = require('./collisions')
utils = require '../utils'

class GameServer
	constructor: (@socket) ->
		@now = 0

		@players = {}

		@bullets = {}
		@mines = {}
		@EMPs = {}
		@bonuses = {}
		@planets = {}

		@gameObjects = {}
		@gameObjectCount = 0

	launch: () ->
		for p in @initPlanets()
			@newGameObject (id) =>
				p.id = id
				@planets[id] = p

		@spawnBonus()
		setInterval(( () => @spawnBonus() ), prefs.bonus.waitTime)

		# Bind socket events
		@socket.on 'clientConnect', (client) =>
			@clientConnect(client)

		@socket.on 'clientMessage', (msg, client) =>
			@clientMessage(msg, client)

		@socket.on 'clientDisconnect', (client) =>
			@clientDisconnect(client)

		# Setup space grid
		@grid =
			width: prefs.server.grid.width
			height: prefs.server.grid.height
			cellWidth: prefs.server.mapSize.w / prefs.server.grid.width
			cellHeight: prefs.server.mapSize.h / prefs.server.grid.height
			cells: {}

		@update()

	clientConnect: (client) ->
		id = client.sessionId

		# Add new player to player list.
		player = @players[id] = new Player(id)

		client.send
			type: 'connected'
			playerId: id

	createShip: (client) ->
		id = client.sessionId
		player = @players[id]

		# Create ship.
		@newGameObject( (id) ->
			player.createShip(id) )

		# Send game objects.
		objs = @watched(@gameObjects)
		if not utils.isEmptyObject objs
			client.send
				type: 'objects update'
				objects: objs

		# Good news!
		client.send
			type: 'ship created'
			playerId: id
			shipId: player.ship.id

	watched: (objs) ->
		allWatched = {}

		for id, obj of objs
			objWatched = obj.watched()
			if not utils.isEmptyObject objWatched
				allWatched[id] = objWatched

		return allWatched

	clientMessage: (msg, client) ->
		return if not @players[msg.playerId]?

		switch msg.type
			when 'key down'
				@players[msg.playerId].keyDown(msg.key)

			when 'key up'
				@players[msg.playerId].keyUp(msg.key)

			when 'create ship'
				@createShip(client)

			when 'prefs changed'
				@players[msg.playerId].changePrefs(msg.name, msg.color)

	clientDisconnect: (client) ->
		playerId = client.sessionId
		shipId = @players[playerId].ship?.id

		# Tell everyone.
		client.broadcast
			type: 'player quits'
			playerId: playerId
			shipId : shipId

		# Purge objects belonging to client.
		@deleteObject(shipId)
		delete @players[playerId]

	# Game loop
	update: () ->
		start = @now = (new Date).getTime()

		player.update() for id, player of @players

		@updateObjects(@gameObjects)

		diff = (new Date).getTime() - start
		setTimeout(( () => @update() ),
			prefs.server.timestep - utils.mod(diff, prefs.server.timestep))

	placeObjectInGrid: (obj) ->
		{w: mapWidth, h: mapHeight} = prefs.server.mapSize
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

		# First place object in the cell containing (x,y)
		insert(ox, oy)

		# Now place it in adjacent squares
		r = obj.hitRadius

		insert(ox-r, oy-r)
		insert(ox-r, oy+r)
		insert(ox+r, oy-r)
		insert(ox+r, oy+r)

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
			@socket.broadcast
				type: 'objects update'
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

		mapW = prefs.server.mapSize.w
		mapH = prefs.server.mapSize.h

		# If a planet is overlapping the map, it will appear to be
		# colliding with its ghosts in drawInfinity.
		nearBorder = (x, y, r) ->
			(x - r < 0 or x + r > mapW or y - r < 0 or y + r > mapH)

		min = prefs.planet.minForce
		marge = prefs.planet.maxForce - min

		satAbsFMin = prefs.planet.satelliteAbsMinForce
		satFMin = prefs.planet.satelliteMinForce
		satFMarge = prefs.planet.satelliteMaxForce - satFMin

		satGMin = prefs.planet.satelliteMinGap
		satGMarge = prefs.planet.satelliteMaxGap - satGMin

		# Spawn planets randomly.
		for [0...prefs.planet.count]
			satellite = Math.random() < prefs.planet.satelliteChance
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
				planets.push new Moon(rock, satForce, satGap)

		return planets

	spawnBonus: (bonusType) ->
		return false if Object.keys(@bonuses).length >= prefs.bonus.maxCount
		@newGameObject( (id) =>
			@bonuses[id] = new Bonus(id, bonusType) )

exports.GameServer = GameServer
