port = 12345

http = require 'http'
io = require 'socket.io'
url = require 'url'
fs = require 'fs'

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# HTTP server setup
#

js = (path) ->
	path.match(/js$/)

server = http.createServer (req, res) ->
	path = url.parse(req.url).pathname
	switch path
		when '/client.html', '/client.js', '/jquery.js'
			fs.readFile __dirname + '/../..' + path, (err, data) ->
				return send404(res) if err?
				res.writeHead 200,
					'Content-Type': if js path then 'text/javascript' else 'text/html'
				res.write data, 'utf8'
				res.end()
		else send404(res)

send404 = (res) ->
	res.writeHead 404, 'Content-Type': 'text/html'
	res.end '<h1>Nothing to see here, move along</h1>'

server.listen port

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Socket.IO setup

prefs = require './prefs'
Player = require './player'
Bonus = require './bonus'
Planet = require './planet'
utils = require '../utils'

io = io.listen server

io.on 'clientConnect', (client) ->
	id = client.sessionId

	# Add new player to player list.
	player = exports.players[id] = new Player.Player(id)

	# Create ship.
	exports.newGameObject( (id) ->
		player.createShip(id) )

	# Send the playfield.
	client.send
		type: 'objects update'
		objects: exports.planets

	# Send game objects.
	client.send
		type: 'objects update'
		objects: exports.gameObjects

	# Good news!
	client.send
		type: 'connected'
		playerId: id
		shipId: player.ship.id

io.on 'clientMessage', (msg, client) ->
	switch msg.type
		when 'key down'
			exports.players[msg.playerId].keyDown(msg.key)
		when 'key up'
			exports.players[msg.playerId].keyUp(msg.key)

io.on 'clientDisconnect', (client) ->
	id = client.sessionId

	# Tell everyone.
	client.broadcast
		type: 'player quits'
		playerId: id
		shipId : exports.players[id].ship.id

	# Purge objects belonging to client.
	delete exports.players[id]

console.log "Server started"

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Game server handling
#

# Globals

exports.now = 0

exports.players = {}

exports.bullets = {}
exports.mines = {}
exports.bonuses = {}
exports.planets = {}

exports.gameObjects = {}
exports.gameObjectCount = 0

# Game loop
update = () ->
	start = now = (new Date).getTime()

	player.update() for id, player of exports.players

	updateObjects(exports.gameObjects)

	diff = (new Date).getTime() - start
	setTimeout(update, prefs.server.timestep - utils.mod(diff, 20))

updateObjects = (objects) ->
	# Move all objects
	obj.move() for id, obj of objects

	# Check collisions with planets
	for i, planet of exports.planets
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
		deleteObject id if obj.serverDelete

	# Broadcast changes to all players.
	if not utils.isEmptyObject allChanges
		io.broadcast
			type: 'objects update'
			objects: allChanges

exports.newGameObject = (creator) ->
	id = exports.gameObjectCount++
	exports.gameObjects[id] = creator(id)

deleteObject = (id) ->
	type = exports.gameObjects[id].type

	switch type
		when 'bonus'
			delete exports.bonuses[id]
		when 'bullet'
			delete exports.bullets[id]
		when 'mine'
			delete exports.mines[id]
		when 'planet'
			delete exports.planets[id]

	delete exports.gameObjects[id]

initPlanets = () ->
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
		while colliding			  # Ensure none are colliding
			rock = new Planet.Planet(Math.random() * prefs.server.mapSize.w,
				Math.random() * prefs.server.mapSize.h,
				50+Math.random()*50)
			colliding = no
			for p in planets
				colliding = yes if nearBorder(rock) or collides(p,rock)
		planets.push rock

	return planets

spawnBonus = () ->
	exports.newGameObject (id) ->
		exports.bonuses[id] = new Bonus.Bonus(id)

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Launch the game loop once everything is defined.

launch = () ->
	for p in initPlanets()
		id = exports.gameObjectCount++
		exports.planets[id] = p

	spawnBonus()
	setInterval(spawnBonus, prefs.server.bonusWait)

	update()

launch()
