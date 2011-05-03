port = 12345

http = require 'http'
io = require 'socket.io'
url = require 'url'
fs = require 'fs'

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# HTTP server setup
#

server = http.createServer (req, res) ->
	path = url.parse(req.url).pathname
	switch path
		when '/client.html', '/client.js', '/jquery.js'
			fs.readFile __dirname + path, (err, data) ->
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
#

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
	ships[id] = new Ship id

	# Send the playfield.
	player.send
		type: 'planets'
		planets: planets

	# Send ships.
	player.send
		type: 'ships'
		ships: ships

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

dirInc = 0.1
maxPower = 3
minFirepower = 1.3
cannonCooldown = 20
maxBullets = 5
shipSpeed = 0.3
frictionDecay = 0.97
maxExploFrame = 50

map = w: 2000, h: 2000

players = {}
ships = {}
bullets = []
planets = []

processKeyDown = (id, key) ->
	players[id].keys[key] = on

processKeyUp = (id, key) ->
	players[id].keys[key] = off

	# Fire the bullet or respawn if the spacebar is released.
	if key is 32
		if ships[id].isDead()
			ships[id].spawn()
		else
			ships[id].fire()

processInputs = (id) ->
	keys = players[id].keys
	ship = ships[id]

	if not ship? then return

	# Left arrow : rotate to the left.
	if keys[37] is on
		ship.dir -= dirInc
		ship.dirtyFields.dir = yes

	# Right arrow : rotate to the right.
	if keys[39] is on
		ship.dir += dirInc
		ship.dirtyFields.dir = yes

	# Up arrow : thrust forward.
	if keys[38] is on
		ship.vel.x += Math.sin(ship.dir) * shipSpeed
		ship.vel.y -= Math.cos(ship.dir) * shipSpeed

	# Spacebar : charge the bullet.
	if keys[32] is on
		ship.firePower = Math.min(ship.firePower + 0.1, maxPower)
		ship.dirtyFields.firePower = yes

update = () ->
	start = (new Date).getTime()

	processInputs id for id of players

	updateBullets()
	updateShips()

	diff = (new Date).getTime() - start
	setTimeout(update, 20-mod(diff, 20))

updateShips = () ->
	changes = {}
	for id, ship of ships
		ship.update()
		shipChanges = ship.changes()
		if shipChanges != {}
			changes[id] = shipChanges

	io.broadcast
		type: 'update'
		update: changes

updateBullets = () ->
	b.step()	for b in bullets

	if bullets.length > 0
		io.broadcast
			type: 'bullets'
			bullets: bullets

initPlanets = () ->
	(new Planet Math.random()*2000,
		Math.random()*2000,
		50+Math.random()*50) for [0..35]

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Launch the game loop once everything is defined.

launch = () ->
	planets = initPlanets()
	update()
