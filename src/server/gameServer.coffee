prefs = require './prefs'
Player = require('./player').Player
Bonus = require('./bonus').Bonus
Planet = require('./planet').Planet
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
		objs = @watched(@gameObjects)
		if not utils.isEmptyObject objs
			client.send
				type: 'objects update'
				objects: objs

		# Good news!
		client.send
			type: 'connected'
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
		switch msg.type
			when 'key down'
				@players[msg.playerId].keyDown(msg.key)

			when 'key up'
				@players[msg.playerId].keyUp(msg.key)

			when 'prefs changed'
				@players[msg.playerId].changePrefs(msg.name, msg.color)

	clientDisconnect: (client) ->
		playerId = client.sessionId
		shipId = @players[playerId].ship.id

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

	updateObjects: (objects) ->
		# Move all objects
		obj.move() for id, obj of objects

		# Check collisions with planets
		for i, planet of @planets
			for j, obj of objects
				if obj.tangible() and obj.collidesWith(planet)
					collisions.handle(obj, planet)

		# Check all collisions
		for i, obj1 of objects
			for j, obj2 of objects
				if j > i and
						obj1.tangible() and
						obj2.tangible() and
						(obj1.collidesWith(obj2) or obj2.collidesWith(obj1))
					collisions.handle(obj1, obj2)

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
			when 'EMP'
				delete @EMPs[id]

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

	spawnBonus: (bonusType) ->
		return false if Object.keys(@bonuses).length >= prefs.server.maxBonuses
		@newGameObject( (id) =>
			@bonuses[id] = new Bonus(id, bonusType) )

exports.GameServer = GameServer
