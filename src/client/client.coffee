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
explosions = {}

gameObjects = {}

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

# Game loop!
update = () ->
	start = (new Date).getTime()

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

	# Draw all objects.
	obj.draw(ctxt)	for idx, obj of gameObjects

	drawRadar ctxt if ships[id]? and not ships[id].isDead()

	# Draw outside of the map bounds.
	drawInfinity ctxt

centerView = () ->
	if gameObjects[id]?
		view.x = gameObjects[id].pos.x - screen.w/2
		view.y = gameObjects[id].pos.y - screen.h/2

drawRadar = (ctxt) ->
	ship = ships[id]

	for i, s of ships
		if i isnt id and not s.isDead()
			# Select the closest ship among the real one and its ghosts.
			bestDistance = Infinity
			for j in [-1..1]
				for k in [-1..1]
					x = s.pos.x + j * map.w
					y = s.pos.y + k * map.h
					d = distance(ship.pos.x, ship.pos.y, x, y)

					if d < bestDistance
						bestDistance = d
						bestPos = {x, y}

			dx = bestPos.x - ship.pos.x
			dy = bestPos.y - ship.pos.y

			if Math.abs(dx) > screen.w/2 or Math.abs(dy) > screen.h/2

				margin = 20
				rx = Math.max -screen.w/2 + margin, dx
				rx = Math.min screen.w/2 - margin, rx
				ry = Math.max -screen.h/2 + margin, dy
				ry = Math.min screen.h/2 - margin, ry

				# Choose on which ship we should base the animation. If the two
				# of them are exploding, focus on the first to die.
				if s.isExploding() and ship.isExploding()
					dying = if s.exploFrame > ship.exploFrame then s else ship
				else if s.isExploding()
					dying = s
				else if ship.isExploding()
					dying = ship

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
				for idx, obj of gameObjects
					offset =
						x: (j-1)*map.w
						y: (i-1)*map.h
					obj.draw(ctxt, offset)

	return true

onConnect = () ->
	info "Connected to server"

onDisconnect = () ->
	info "Aaargh! Disconnected!"

newObject = (i, type, obj) ->
	switch type
		when 'ship'
			ships[i] = new Ship(obj)
		when 'bullet'
			new Bullet(obj)
		when 'mine'
			new Mine(obj)
		when 'planet'
			new Planet(obj)

onMessage = (msg) ->
	switch msg.type

		# When receiving world update data.
		when 'objects update'
			for i, obj of msg.objects
				if not gameObjects[i]?
					gameObjects[i] = newObject(i, obj.type, obj)
				else
					gameObjects[i].update(obj)

		# When receiving our id from the server.
		when 'connected'
			go(msg.playerId)

		# When another player leaves.
		when 'player quits'
			delete ships[msg.playerId]
			delete gameObjects[msg.playerId]
			console.info 'player '+msg.playerId+' quits'

	return true
