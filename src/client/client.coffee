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
minPower = 1.3
maxPower = 3
maxExploFrame = 50
maxBullets = 10
bulletFrameStay = 4

id = null
ships = {}
serverShips = {}
explosions = {}
planets = []
bullets = {}
mines = []

enableInterpolation = false
interp_factor = .03
lastUpdate = 0
keys = {}

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

	$(document).keydown ({keyCode}) ->
		if not keys[keyCode]? or keys[keyCode] is off
			keys[keyCode] = on
			socket.send
				type: 'key down'
				playerId: id
				key: keyCode

	$(document).keyup ({keyCode}) ->
		keys[keyCode] = off
		socket.send
			type: 'key up'
			playerId: id
			key: keyCode

	update()

interpolate = (time) ->
	#info time if time*interp_factor > 1

	for i, shadow of serverShips
		ship = ships[i]

		if not ship?
			ships[i] = new Ship shadow
			continue

		if time * interp_factor > 1
			ship = shadow
			continue

		if ship.isDead() and not shadow.isDead()
			ships[i] = new Ship shadow
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
		ship.firePower = shadow.firePower
		ship.dead = shadow.dead
		ship.exploding = shadow.exploding
		ship.exploFrame = shadow.exploFrame

# Game loop!
update = () ->
	start = (new Date).getTime()

	interpolate(start - lastUpdate) if enableInterpolation
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
	len = Object.keys(bullets).length
	i = 1
	b.draw ctxt, (i++)/len for idx, b of bullets

	# Draw all mines.
	m.draw(ctxt) for m in mines

	# Draw all planets.
	p.draw ctxt for p in planets

	# Draw all ships.
	s.draw ctxt	for i, s of ships

	drawRadar ctxt if not ships[id].isDead()

	# Draw outside of the map bounds.
	drawInfinity ctxt

centerView = () ->
	if ships[id]?
		view.x = ships[id].pos.x - screen.w/2
		view.y = ships[id].pos.y - screen.h/2

drawRadar = (ctxt) ->
	for i, s of ships
		if i isnt id and not s.isDead()
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

			dx = bestPos.x - ships[id].pos.x
			dy = bestPos.y - ships[id].pos.y

			if Math.abs(dx) > screen.w/2 or Math.abs(dy) > screen.h/2

				margin = 20
				rx = Math.max -screen.w/2 + margin, dx
				rx = Math.min screen.w/2 - margin, rx
				ry = Math.max -screen.h/2 + margin, dy
				ry = Math.min screen.h/2 - margin, ry

				# Choose on which ship we should base the animation. If the two
				# of them are exploding, focus on the first to die.
				if s.isExploding() and ships[id].isExploding()
					dying = if s.exploFrame > ships[id].exploFrame then s else ships[id]
				else if s.isExploding()
					dying = s
				else if ships[id].isExploding()
					dying = ships[id]

				radius = 10
				alpha = 1

				if dying?
					animRatio = dying.exploFrame / maxExploFrame
					radius -= animRatio * 10
					alpha -= animRatio

				ctxt.fillStyle = color(s.color, alpha)
				ctxt.beginPath()
				ctxt.arc(screen.w/2 + rx, screen.h/2 + ry, radius, 0, 2*Math.PI, false)
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

	len = Object.keys(bullets).length
	for i in [0..2]
		for j in [0..2]
			if visibility[i][j] is on
				bi = 1
				for idx, b of bullets
					offset =
						x: (j-1)*map.w
						y: (i-1)*map.h
					b.draw ctxt, (bi++)/len, offset

	for i in [0..2]
		for j in [0..2]
			if visibility[i][j] is on
				for m in [0...mines.length]
					offset =
						x: (j-1)*map.w
						y: (i-1)*map.h
					mines[m].draw(ctxt, offset)

	return true

onConnect = () ->
	info "Connected to server"

onDisconnect = () ->
	info "Aaargh! Disconnected!"

onMessage = (msg) ->
	switch msg.type

		# When received bullet data.
		when 'bullet update'
			for i, bullet of msg.update
				if not bullets[i]?
					keys = Object.keys(bullets)
					if keys.length > maxBullets
						delete bullets[ keys[0] ] # delete oldest bullet
					bullets[i] = new Bullet(bullet)

				bullets[i].update(bullet.lastPoint)

		# When received mine data.
		when 'mine update'
			mines = []
			for i, m of msg.mines
				mines.push new Mine m

		# When received other ship data.
		when 'ships'
			for i, s of msg.ships
				if enableInterpolation
					serverShips[i] = new Ship s
				else
					ships[i] = new Ship s

			lastUpdate = (new Date).getTime()

		# When received world update.
		when 'ship update'
			for i, s of msg.update
				if enableInterpolation
					serverShips[i].update(s)
				else
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
