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
		if Math.abs dx < .1 and Math.abs dx > 100
			ship.pos.x = shadow.pos.x
		else
			ship.pos.x += dx * time * interp_factor

		# Y interpolation
		dy = shadow.pos.y - ship.pos.y
		if Math.abs dy < .1  and Math.abs dy > 100
			ship.pos.y = shadow.pos.y
		else
			ship.pos.y += dy * time * interp_factor

		# Dir interpolation
		ddir = shadow.dir - ship.dir
		if Math.abs ddir < .01
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
	return x >= view.x && x <= view.x + screen.w && y >= view.y && y <= view.y + screen.h

# Clear canvas and draw everything.
# Not efficient, but we don't have that many objects.
redraw = (ctxt) ->
	ctxt.clearRect(0, 0, screen.w, screen.h)
	ctxt.lineWidth = 4
	ctxt.lineJoin = 'round'

	# Draw all bullets with decreasing opacity.
	len = bullets.length
	for i, b of bullets
		b.draw(ctxt, (i+1)/len);

	# Draw all planets.
	for p in planets
		p.draw(ctxt)

	# Draw all ships.
	for i, s of ships
		s.draw ctxt

	#drawRadar ctxt if !ships[id].isDead()
	
	# Draw outside of the map bounds.
	drawInfinity ctxt

centerView = () ->
	if ships[id]?
		view.x = ships[id].pos.x - screen.w / 2
		view.y = ships[id].pos.y - screen.h / 2

drawRadar: (ctxt) ->
	for i, s of ships
		if (i isnt id)
			dx = ships[i].pos.x - ships[id].pos.x
			dy = ships[i].pos.y - ships[id].pos.y
			d = Math.sqrt(dx*dx + dy*dy)
			rx = dx / d * 50;
			ry = dy / d * 50;

			ctxt.strokeStyle = color planetColor
			ctxt.beginPath()
			ctxt.arc(screen.w/2 + rx, screen.h/2 + ry, 2, 0, 2*Math.PI, false)
			ctxt.stroke()

drawInfinity = (ctxt) ->
	# Can the player see the left, right, top and bottom voids?
	left = view.x < 0
	right = view.x > map.w - screen.w
	top = view.y < 0
	bottom = view.y > map.h - screen.h

	visibility = [[left and top,    top,    right and top]
	              [left,           	false,  right],
	              [left and bottom, bottom, right and bottom]]

	for i in [0..2]
		for j in [0..2]
			if visibility[i][j] is on
				for p in planets
					p.draw(ctxt, x: (j-1)*map.w, y: (i-1)*map.h)

	for i in [0..2]
		for j in [0..2]
			if visibility[i][j] is on
				for s in ships
					s.draw(ctxt, x: (j-1)*map.w, y: (i-1)*map.h)

	for i in [0..2]
		for j in [0..2]
			if visibility[i][j] is on
				for b in bullets
					b.draw(ctxt, 255, x: (j-1)*map.w, y: (i-1)*map.h)

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
			serverShips = ships = {}

			for i, s of msg.ships
				serverShips[i] = new Ship s
				ships[i] = new Ship s

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
			console.info 'new payer joins'

		# When another player dies.
		when 'player dies'
			console.info 'player dies'

		# When another player leaves.
		when 'player quits'
			console.info 'player quits'
