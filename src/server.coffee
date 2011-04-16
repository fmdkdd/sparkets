port = 12345

http = require 'http'
io = require 'socket.io'
url = require 'url'
fs = require 'fs'

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Utilities
#

log = (msg) ->
	console.log msg

error = (msg) ->
	console.error msg

js = (path) ->
	 return path.match(/js$/)

mod = (x, n) ->
	if x > 0 then return x%n else return n+(x%n)

distance = (x1, y1, x2, y2) ->
	return Math.sqrt((x1-x2)*(x1-x2) + (y1-y2)*(y1-y2))

randomColor = () ->
	return Math.round(70 + Math.random()*150) + ',' + Math.round(70 + Math.random()*150) + ',' + Math.round(70 + Math.random()*150)

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# HTTP server setup
#

server = http.createServer (req, res) ->
	path = url.parse(req.url).pathname
	switch path
		when '/client.html', '/client.js'
			fs.readFile __dirname + path, (err, data) ->
				return send404(res) if err?
				res.writeHead 200, 'Content-Type': if js path then 'text/javascript' else 'text/html'
				res.write data, 'utf8'
				res.end()
		else send404(res)

send404 = (res) ->
	res.writeHead 404, {'Content-Type':'text/html'}
	res.end '<h1>Nothing to see here, move along</h1>'

server.listen port

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Socket.IO setup
#

io = io.listen server

io.on 'clientConnect', (player) ->
	# Send list of connected players.
	for id of players
		player.send type: 'player list',
								playerId: id

	# Add new player to player list.
	id = player.sessionId
	players[id] = {}
	players[id].id = id
	players[id].keys = {}

	# Create ship.
	ships[id] = new Ship id

	# Send the playfield.
	player.send type: 'planets', planets: planets

	# Send ships.
	player.send type: 'ships', ships: ships

	# Good news!
	player.send type: 'connected', playerId: id

	# Poke all other players.
	player.broadcast type: 'player joins', playerId: id

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

processKeyDown = (id, key) ->
	players[id].keys[key] = on

processKeyUp = (id, key) ->
	players[id].keys[key] = off

	# fire the bullet if the spacebar is released
	if key is 32
		ships[id].fire()

processInputs = (id) ->
	keys = players[id].keys
	ship = ships[id]

	if not ship? or ship.isDead() then return

	# left arrow : rotate to the left
	if keys[37] is on
		ship.dir -= dirInc

	# right arrow : rotate to the right
	if keys[39] is on
		ship.dir += dirInc

	# up arrow : thrust forward
	if keys[38] is on
		ship.vel.x += Math.sin(ship.dir) * shipSpeed
		ship.vel.y -= Math.cos(ship.dir) * shipSpeed

	# spacebar : charge the bullet
	if keys[32] is on
		ship.firePower = Math.min(ship.firePower + 0.1, maxPower)

update = () ->
	start = (new Date).getTime()

	for id of players
		processInputs id

	updateBullets()
	updateShips()

	diff = (new Date).getTime() - start
	setTimeout(update, 20-mod(diff, 20))

updateShips = () ->
	for i, s of ships
		s.update()

	io.broadcast
		type: 'ships'
		ships: ships

updateBullets = () ->
	for b in bullets
		b.step()
	#console.log bullets.length + ' bullets'
	io.broadcast
		type: 'bullet'
		bullets: bullets

initPlanets = () ->
	planets = []
	for [0..35]
		planets.push new Planet Math.random()*2000,
		                        Math.random()*2000,
		                        50+Math.random()*50

	return planets

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Ship
#

class Ship
	constructor: (id) ->
		@id = id
		@pos = x: Math.random()*map.w, y: Math.random()*map.h
		@vel = x: 0, y: 0
		@dir = Math.random() * 2*Math.PI
		@color = randomColor()
		@firePower = minFirepower
		@cannonHeat = 0
		@dead = false

	update: () ->
		@move()
		--@coolDown

	move: () ->
		@pos.x += @vel.x
		@pos.y += @vel.y

		# Warp the ship around the map
		@pos.x = if @pos.x < 0 then map.w else @pos.x
		@pos.x = if @pos.x > map.w then 0 else @pos.x
		@pos.y = if @pos.y < 0 then map.h else @pos.y
		@pos.y = if @pos.y > map.h then 0 else @pos.y

		@vel.x *= frictionDecay
		@vel.y *= frictionDecay

	collides: () ->
		return @collidesWithOtherShip or
			@collidesWithPlanet() or
			@collidesWithBullet()

	collidesWithOtherShip: () ->
		x = @pos.x
		y = @pos.y

		for s in ships
			if @ isnt s and
				Math.abs(x - ship.pos.x) < 10 and
			  Math.abs(y - ship.pos.y) < 10
				return true
		return false

	collidesWithPlanet: () ->
		x = @pos.x
		y = @pos.y

		return planets.some (p) =>
			px = p.pos.x py = p.pos.y
			return (Math.sqrt((px-x)*(px-x) + (py-y)*(py-y)) < p.force)

	collidesWithBullet: () ->
		x = @pos.x
		y = @pos.y

		for b in bullets
			if not b.dead and
				Math.abs(x - b.pos.x) < 10 and
			  Math.abs(y - b.pos.y) < 10
				b.dead = true
				return true

		return false

	isDead: () ->
		return @dead or @exploBits?

	 () ->
		return if @dead

		if @exploBits?
			@updateExplosion()
		else
			--@cannonHeat
			@move()
			@explode if @collides()
	
	fire : () ->
		return if @isDead() or @cannonHeat > 0

		bullets.push new Bullet @
		bullets.shift if bullets.length > maxBullets

		@firePower = minFirepower
		@cannonHeat = cannonCooldown

	explode : () ->
		@exploBits = []
		@exploFrame = 0
		vel = Math.max @vel.x, @vel.y

		for [0..200]
			@exploBits.push x: @pos.x,
											y: @pos.y,
											vx : .5*vel * (2*Math.random() -1),
											vy : .5*vel * (2*Math.random() -1)

	updateExplosion : () ->
		for b in @exploBits
			b.x += b.vx + (2*Math.random() -1)/1.5
			b.y += b.vy + (2*Math.random() -1)/1.5

		++@exploFrame

		if @exploFrame > maxExploFrame
			@dead = true
			delete ships[@id]
			delete @exploBits
			delete @exploFrame

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Bullet
#

class Bullet
	constructor: (@owner) ->
		@pos =
			x: @owner.pos.x
			y: @owner.pos.y
		@accel =
			x: @owner.vel.x + 10*@power*Math.sin(owner.dir)
			y: @owner.vel.y + -10*@power*Math.cos(owner.dir)
		@power = @owner.firePower
		@dead = false
		
		@color = owner.color
		@points = [[@pos.x + 10*Math.sin(owner.dir),
	              @pos.y - 10*Math.cos(owner.dir)]]

	step: () ->
		return if @dead

		# Compute new position from acceleration and gravity of all planets.
		x = @pos.x
		y = @pos.y
		ax = @accel.x
		ay = @accel.y

		for p in planets
			d = (p.pos.x-x)*(p.pos.x-x) + (p.pos.y-y)*(p.pos.y-y)
			d2 = 200 * p.force / (d * Math.sqrt(d))
			ax -= (x-p.pos.x) * d2
			ay -= (y-p.pos.y) * d2

		nx = x + ax
		ny = y + ay

		@points.push [nx, ny]

		@pos.x = nx
		@pos.y = ny
		@accel.x = ax
		@accel.y = ay

		# Warp the bullet around the map.
		@pos.x = if @pos.x < 0 then map.w else @pos.x
		@pos.x = if @pos.x > map.w then 0 else @pos.x
		@pos.y = if @pos.y < 0 then map.h else @pos.y
		@pos.y = if @pos.y > map.h then 0 else @pos.y

		@dead = true if @collides()

	collides : () ->
		return @collidesWithPlanet()

	collidesWithPlanet : () ->
		x = @pos.x
		y = @pos.y

		return planets.some (p) ->
			px = p.pos.x
			py = p.pos.y
			return (Math.sqrt((px-x)*(px-x) + (py-y)*(py-y)) < p.force)

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Planet
#

class Planet
	constructor: (x, y, @force) ->
		@pos = x: x, y: y

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Launch the game loop once everything is defined.
#

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
planets = initPlanets()

update()
