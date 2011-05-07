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
Ship = require './ship'
Bullet = require './bullet'
Bonus = require './bonus'
Planet = require './planet'
utils = require '../utils'

io = io.listen server

io.on 'clientConnect', (player) ->
	# Send list of connected players.
	for id of exports.players
		player.send
			type: 'player list'
			playerId: id

	# Add new player to player list.
	id = player.sessionId
	exports.players[id] =
		id: id
		keys: {}

	# Create ship.
	exports.gameObjects[id] = exports.ships[id] = new Ship.Ship id

	# Send the playfield.
	player.send
		type: 'objects update'
		objects: exports.planets

	# Send other game objects.
	player.send
		type: 'objects update'
		objects: exports.gameObjects

	# Good news!
	player.send
		type: 'connected'
		playerId: id

io.on 'clientMessage', (msg, player) ->
	switch msg.type
		when 'key down' then processKeyDown msg.playerId, msg.key
		when 'key up' then processKeyUp msg.playerId, msg.key

io.on 'clientDisconnect', (player) ->
	# Purge from list.
	id = player.sessionId
	delete exports.players[id]
	deleteObject(id, exports.ships[id])

	# Tell everyone.
	player.broadcast
		type: 'player quits'
		playerId : id

console.log "Server started"

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Game server handling
#

# Globals

exports.now = 0

exports.players = {}

exports.ships = {}
exports.bullets = {}
exports.mines = {}
exports.bonuses = {}
exports.planets = {}

exports.gameObjects = {}
exports.gameObjectCount = 0

# Input processing

processKeyDown = (id, key) ->
	exports.players[id].keys[key] = on

processKeyUp = (id, key) ->
	exports.players[id].keys[key] = off

	# Fire the bullet or respawn if the spacebar is released.
	if key is 32 or key is 65
		if exports.ships[id].isDead()
			exports.ships[id].spawn()
		else
			exports.ships[id].fire()

	if key is 38
		exports.ships[id].thrust = false

	# Z : drop a mine.
	if key is 90
		exports.ships[id].dropMine()

processInputs = (id) ->
	keys = exports.players[id].keys
	ship = exports.ships[id]

	if not ship? then return

	# Left arrow : rotate to the left.
	if keys[37] is on
		ship.dir -= prefs.ship.dirInc

	# Right arrow : rotate to the right.
	if keys[39] is on
		ship.dir += prefs.ship.dirInc

	# Up arrow : thrust forward.
	if keys[38] is on
		ship.vel.x += Math.sin(ship.dir) * prefs.ship.speed
		ship.vel.y -= Math.cos(ship.dir) * prefs.ship.speed
		ship.thrust = true

	# Spacebar : charge the bullet.
	if keys[32] or keys[65]
		ship.firePower = Math.min(ship.firePower + 0.1, prefs.ship.maxFirepower)

# Game loop
update = () ->
	start = now = (new Date).getTime()

	processInputs id for id of exports.players

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
		deleteObject(id, obj) if obj.deleteMe

	# Broadcast changes to all players.
	if not utils.isEmptyObject allChanges
		io.broadcast
			type: 'objects update'
			objects: allChanges

deleteObject = (id, obj) ->
	switch obj.type
		when 'bonus'
			delete exports.bonuses[id]
		when 'bullet'
			delete exports.bullets[id]
		when 'mine'
			delete exports.mines[id]
		when 'planet'
			delete exports.planets[id]
		when 'ship'
			delete exports.ships[id]
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
			rock = new Planet.Planet(Math.random()*2000,
				Math.random()*2000,
				50+Math.random()*50)
			colliding = no
			for p in planets
				colliding = yes if nearBorder(rock) or collides(p,rock)
		planets.push rock

	return planets

spawnBonus = () ->
	id = exports.gameObjectCount++
	exports.gameObjects[id] = exports.bonuses[id] = new Bonus.Bonus(id)

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
