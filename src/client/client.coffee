# Server
port = 12345
socket = {}

# Graphics
ctxt = null
screen = {w: 0, h: 0}
map = {w: 2000, h: 2000}
view = {x: 0, y: 0}

planetColor = '127, 157, 185'

# Game logic
maxPower = 3
maxExploFrame = 50

id = null
ships = {}
serverShips = {}
explosions = {}
planets = []
bullets = []

interp_factor = .03
lastUpdate = 0

# Entry point
$(document).ready (event) ->
	# Connect to server and set callbacks.
	socket = new io.Socket null, {port: port}
	socket.connect()
	socket.on 'message', onMessage
	socket.on 'connect', onConnect
	socket.on 'disconnect', onDisconnect

	# Setup canvas.
	ctxt = document.getElementById('canvas').getContext('2d')

	# Setup window resizing event.
	$(window).resize (event) =>
		screen.w = document.getElementById('canvas').width = window.innerWidth
		screen.h = document.getElementById('canvas').height = window.innerHeight
		centerView()
	$(window).resize()

# Setup input callbacks and launch game loop.
go = (clientId) ->
	id = clientId

	$(document).keydown (event) ->
		socket.send
			type: 'key down'
			playerId: id
			key: event.keyCode

	$(document).keyup (event) ->
		socket.send
			type: 'key up'
			playerId: id
			key: event.keyCode

	update()

interpolate = (time) ->
	#info time if time*interp_factor > 1

	for i, ship of serverShips
		shadow = serverShips[i]

		if not ship?
			ships[i] = shadow
			continue

		# X interpolation
		dx = shadow.pos.x - ship.pos.x
		if -.1 < dx < .1 or dx > 100 or dx < -100
			ship.pos.x = shadow.pos.x
		else
			ship.pos.x += dx * time * interp_factor

		# Y interpolation
		dy = shadow.pos.y - ship.pos.y
		if -.1 < dy < .1 or dy > 100 or dy < -100
			ship.pos.y = shadow.pos.y
		else
			ship.pos.y += dy * time * interp_factor

		# Dir interpolation
		ddir = shadow.dir - ship.dir
		if -.01 < ddir < .01
			ship.dir = shadow.dir
		else
			ship.dir += ddir * time * interp_factor

		# Everything else
		ship.vel = shadow.vel
		ship.color = shadow.color
		ship.firePower = shadow.firePower
		ship.dead = shadow.dead
		ship.exploBits = shadow.exploBits
		ship.exploFrame = shadow.exploFrame

# Game loop!
update = () ->
	start = (new Date).getTime()

	interpolate((new Date).getTime() - lastUpdate)
	centerView()
	redraw(ctxt)

	diff = (new Date).getTime() - start
	setTimeout(update, 20-mod(diff, 20))

inView = (x, y) ->
	view.x <= x <= view.x + screen.w and
	view.y <= y <= view.y + screen.h

# Clear canvas and draw everything.
# Not efficient, but we don't have that many objects.
redraw = (ctxt) ->
	ctxt.clearRect(0, 0, screen.w, screen.h)
	ctxt.lineWidth = 4
	ctxt.lineJoin = 'round'

	# Draw all bullets with decreasing opacity.
	len = bullets.length
	b.draw ctxt, (i+1)/len for b,i in bullets

	# Draw all planets.
	p.draw ctxt for p in planets

	# Draw all ships.
	s.draw ctxt	for i, s of ships

	drawRadar ctxt if not ships[id].isDead() and not ships[id].isExploding()

	# Draw outside of the map bounds.
	drawInfinity ctxt

centerView = () ->
	if ships[id]?
		view.x = ships[id].pos.x - screen.w/2
		view.y = ships[id].pos.y - screen.h/2

drawRadar = (ctxt) ->
	for i, s of ships
		if i isnt id and not s.isDead() and not s.isExploding()

			dx = s.pos.x - ships[id].pos.x
			dy = s.pos.y - ships[id].pos.y

			if Math.abs(dx) > screen.w/2 or Math.abs(dy) > screen.h/2
				# Select the closest ship among the real one and its ghosts.
				bestDistance = 999999
				for j in [-1..1]
					for k in [-1..1]
						x = s.pos.x + j * map.w
						y = s.pos.y + k * map.h
						d = distance(ships[id].pos.x, ships[id].pos.y, x, y)

						if d < bestDistance
							bestDistance = d
							bestPos = {x: x, y: y}

				margin = 20
				rx = Math.max -screen.w/2 + margin, bestPos.x - ships[id].pos.x
				rx = Math.min screen.w/2 - margin, rx
				ry = Math.max -screen.h/2 + margin, bestPos.y - ships[id].pos.y
				ry = Math.min screen.h/2 - margin, ry

				ctxt.fillStyle = color s.color
				ctxt.beginPath()
				ctxt.arc(screen.w/2 + rx, screen.h/2 + ry, 10, 0, 2*Math.PI, false)
				ctxt.fill()

	return true

drawInfinity = (ctxt) ->
	# Can the player see the left, right, top and bottom voids?
	left = view.x < 0
	right = view.x > map.w - screen.w
	top = view.y < 0
	bottom = view.y > map.h - screen.h

	visibility = [[left and top,    top,    right and top]
	              [left,           	off,  right],
	              [left and bottom, bottom, right and bottom]]

	for i in [0..2]
		for j in [0..2]
			if visibility[i][j] is on
				for p in planets
					offset =
						x: (j-1)*map.w
						y: (i-1)*map.h
					p.draw ctxt, offset

	for i in [0..2]
		for j in [0..2]
			if visibility[i][j] is on
				for id, s of ships
					offset =
						x: (j-1)*map.w
						y: (i-1)*map.h
					s.draw ctxt, offset

	len = bullets.length
	for i in [0..2]
		for j in [0..2]
			if visibility[i][j] is on
				for b in [0...bullets.length]
					offset =
						x: (j-1)*map.w
						y: (i-1)*map.h
					bullets[b].draw ctxt, (b+1)/len, offset

	return true

onConnect = () ->
	info "Connected to server"

onDisconnect = () ->
	info "Aaargh! Disconnected!"

onMessage = (msg) ->
	switch msg.type

		# When received bullet data.
		when 'bullets'
			bullets = []
			for b in msg.bullets
				bullets.push new Bullet b

		# When received other ship data.
		when 'ships'
			for i, s of msg.ships
				serverShips[i] = new Ship s
				ships[i] = new Ship s

			lastUpdate = (new Date).getTime()

		# When received world update.
		when 'update'
			for i, s of msg.update
				serverShips[i].update(s)
				ships[i].update(s)

			lastUpdate = (new Date).getTime()

		# When received planet data.
		when 'planets'
			planets = []
			for p in msg.planets
				planets.push new Planet p

		# When receiving our id from the server.
		when 'connected'
			go(msg.playerId)

		# When another player joins.
		when 'player joins'
			serverShips[msg.playerId] = new Ship msg.ship
			ships[msg.playerId] = new Ship msg.ship
			console.info 'player '+msg.playerId+' joins'

		# When another player dies.
		when 'player dies'
			delete serverShips[msg.playerId]
			delete ships[msg.playerId]
			console.info 'player '+msg.playerId+' dies'

		# When another player leaves.
		when 'player quits'
			delete serverShips[msg.playerId]
			delete ships[msg.playerId]
			console.info 'player '+msg.playerId+' quits'

	return true
