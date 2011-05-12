prefs = require './prefs'
Player = require('./player').Player
Bonus = require('./bonus').Bonus
Planet = require('./planet').Planet
utils = require '../utils'

class GameServer
	constructor: (@socket) ->
		@now = 0

		@players = {}

		@bullets = {}
		@mines = {}
		@bonuses = {}
		@planets = {}

		@gameObjects = {}
		@gameObjectCount = 0

	launch: () ->
		for p in @initPlanets()
			id = @gameObjectCount++
			@planets[id] = p

		@spawnBonus()
		setInterval(( () => @spawnBonus() ), prefs.server.bonusWait)

		# Bind socket events
		@socket.on 'clientConnect', (client) =>
			@clientConnect(client)

		@socket.on 'clientMessage', (msg, client) =>
			@clientMessage(msg, client)

		@socket.on 'clientDisconnect', (client) =>
			@clientDisconnect(client)

		@update()

	clientConnect: (client) ->
		id = client.sessionId

		# Add new player to player list.
		player = @players[id] = new Player(id)

		# Create ship.
		@newGameObject( (id) ->
			player.createShip(id) )

		# Send the playfield.
		client.send
			type: 'objects update'
			objects: @planets

		# Send game objects.
		client.send
			type: 'objects update'
			objects: @gameObjects

		# Good news!
		client.send
			type: 'connected'
			playerId: id
			shipId: player.ship.id

	clientMessage: (msg, client) ->
		switch msg.type
			when 'key down'
				@players[msg.playerId].keyDown(msg.key)

			when 'key up'
				@players[msg.playerId].keyUp(msg.key)

			when 'name changed'
				@players[msg.playerId].name = msg.name
				console.log msg.name

	clientDisconnect: (client) ->
		id = client.sessionId

		# Tell everyone.
		client.broadcast
			type: 'player quits'
			playerId: id
			shipId : @players[id].ship.id

		# Purge objects belonging to client.
		delete @players[id]

	# Game loop
	update: () ->
		start = @now = (new Date).getTime()

		player.update() for id, player of @players

		@updateObjects(@gameObjects)

		diff = (new Date).getTime() - start
		setTimeout(( () => @update() ),
			prefs.server.timestep - utils.mod(diff, prefs.server.timestep))

	updateObjects: (objects) ->
		# Move all objects
		obj.move() for id, obj of objects

		# Check collisions with planets
		for i, planet of @planets
			for j, obj of objects
				if obj.collidesWith(planet)
					obj.collisions.push(planet)

		# Check all collisions
		for i, obj1 of objects
			for j, obj2 of objects
				if j > i and
						obj1.tangible() and
						obj2.tangible() and
						(obj1.collidesWith(obj2) or obj2.collidesWith(obj1))
					obj1.collisions.push(obj2)
					obj2.collisions.push(obj1)

		# Record all changes.
		allChanges = {}
		for id, obj of objects
			# Let object update
			obj.update()

			# Clear its collisions
			obj.collisions = []

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
		type = @gameObjects[id].type

		switch type
			when 'bonus'
				delete @bonuses[id]
			when 'bullet'
				delete @bullets[id]
			when 'mine'
				delete @mines[id]
			when 'planet'
				delete @planets[id]

		delete @gameObjects[id]

	initPlanets: () ->
		planets = []

		collides = (p1, p2) ->
			(utils.distance(p1.pos.x, p1.pos.y,
				p2.pos.x, p2.pos.y) < p1.force + p2.force)

		# If a planet is overlapping the map, it will appear to be
		# colliding with its ghosts in drawInfinity.
		nearBorder = ({pos: {x, y}, force}) ->
			(x - force < 0 or x + force > prefs.server.mapSize.w or
				y - force < 0 or y + force > prefs.server.mapSize.h)

		# Spawn planets randomly.
		for [0...prefs.server.planetsCount]
			colliding = yes
			while colliding		  # Ensure none are colliding
				rock = new Planet(Math.random() * prefs.server.mapSize.w,
					Math.random() * prefs.server.mapSize.h,
					50+Math.random()*50)
				colliding = no
				for p in planets
					colliding = yes if nearBorder(rock) or collides(p,rock)
			planets.push rock

		return planets

	spawnBonus: () ->
		@newGameObject( (id) =>
			@bonuses[id] = new Bonus(id) )

exports.GameServer = GameServer
