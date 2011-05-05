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
Planet = require './planet'
utils = require '../utils'

io = io.listen server

io.on 'clientConnect', (player) ->
	# Send list of connected players.
	for id of players
		player.send
			type: 'player list'
			playerId: id

	# Add new player to player list.
	id = player.sessionId
	players[id] =
		id: id
		keys: {}

	# Create ship.
	ships[id] = new Ship.Ship id

	# Send the playfield.
	player.send
		type: 'planets'
		planets: planets

	# Send ships.
	player.send
		type: 'ships'
		ships: ships

	# Send existing mines.
	player.send
		type: 'mine update'
		mines: mines

	# Good news!
	player.send
		type: 'connected'
		playerId: id

	# Poke all other players.
	player.broadcast
		type: 'player joins'
		playerId: id
		ship: ships[id]

io.on 'clientMessage', (msg, player) ->
	switch msg.type
		when 'key down' then processKeyDown msg.playerId, msg.key
		when 'key up' then processKeyUp msg.playerId, msg.key

io.on 'clientDisconnect', (player) ->
	# Purge from list.
	id = player.sessionId
	delete players[id]
	delete ships[id]

	# Tell everyone.
	player.broadcast
		type: 'player quits'
		playerId : id

console.log "Server started"

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Game server handling
#

# Globals

now = 0

players = {}
ships = {}
bullets = []
bulletCount = 0
mines = {}
mineCount = 0
planets = []

# Input processing

processKeyDown = (id, key) ->
	players[id].keys[key] = on

processKeyUp = (id, key) ->
	players[id].keys[key] = off

	# Fire the bullet or respawn if the spacebar is released.
	if key is 32 or key is 65
		if ships[id].isDead()
			ships[id].spawn()
		else
			ships[id].fire()

	# Z : drop a mine.
	if key is 90
		ships[id].dropMine()

processInputs = (id) ->
	keys = players[id].keys
	ship = ships[id]

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

	# Spacebar : charge the bullet.
	if keys[32] or keys[65]
		ship.firePower = Math.min(ship.firePower + 0.1, prefs.ship.maxFirepower)

update = () ->
	start = now = (new Date).getTime()

	processInputs id for id of players

	updateBullets()
	updateMines()
	updateShips()

	diff = (new Date).getTime() - start
	setTimeout(update, prefs.server.timestep - utils.mod(diff, 20))

updateShips = () ->
	changes = {}
	for id, ship of ships
		ship.update()
		shipChanges = ship.changes()
		if not utils.isEmptyObject shipChanges
			changes[id] = shipChanges
			ship.resetChanges()

	if not utils.isEmptyObject changes
		io.broadcast
			type: 'ship update'
			update: changes

updateBullets = () ->
	changes = {}

	for bullet in bullets
		bullet.step()
		bulletChanges = bullet.changes()
		if not utils.isEmptyObject bulletChanges
			changes[bullet.id] = bulletChanges
			bullet.resetChanges()

	if not utils.isEmptyObject changes
		io.broadcast
			type: 'bullet update'
			update: changes

updateMines = () ->
	changes = {}

	for i, mine of mines
		mine.update()
		mineChanges = mine.changes()
		if not utils.isEmptyObject mineChanges
			changes[mine.id] = mineChanges
			mine.resetChanges()

	if not utils.isEmptyObject changes
		io.broadcast
			type: 'mine update'
			mines: mines

initPlanets = () ->
	_planets = []

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
			for p in _planets
				colliding = yes if nearBorder(rock) or collides(p,rock)
		_planets.push rock

	return _planets

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Launch the game loop once everything is defined.

launch = () ->
	planets = initPlanets()

	# Exports

	exports.now = now

	exports.ships = ships
	exports.bullets = bullets
	exports.bulletCount = bulletCount
	exports.mines = mines
	exports.mineCount = mineCount
	exports.planets = planets

	update()

launch()
