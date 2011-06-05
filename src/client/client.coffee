# Server
window.port = 12345
window.socket = {}

# Graphics
window.ctxt = null
window.screen = {w: 0, h: 0}
window.map = {w: 2000, h: 2000}
window.view = {x: 0, y: 0}

# Time
window.now = null
window.sinceLastUpdate = null

window.planetColor = [209,29,61]
window.maxBulletLength = 15

# Game logic
window.minPower = 1.3
window.maxPower = 3
window.maxExploFrame = 50
window.maxBullets = 10
window.cannonCooldown = 20

window.playerId = null
window.shipId = null
window.localShip = null

window.ships = {}
window.bonuses = {}

window.gameObjects = {}

window.keys = {}

window.menu = null

# user preferences
window.displayNames = no

# Debugging
window.showHitCircles = no
window.showMapBounds = no
window.showFPS = no

# Entry point
$(document).ready (event) ->

	# Restore local preferences.
	window.menu = new Menu()
	window.menu.restoreLocalPreferences()

	# Connect to server and set callbacks.
	window.socket = new io.Socket null, {port: window.port}
	window.socket.connect()
	window.socket.on 'message', onMessage
	window.socket.on 'connect', onConnect
	window.socket.on 'disconnect', onDisconnect

	# Setup canvas.
	window.ctxt = document.getElementById('canvas').getContext('2d')

	# Setup window resizing event.
	$(window).resize (event) =>
		window.screen.w = document.getElementById('canvas').width = window.innerWidth
		window.screen.h = document.getElementById('canvas').height = window.innerHeight
		centerView()
	$(window).resize()

# Setup input callbacks and launch game loop.
go = () ->
	# Show the menu the first time.
	if not window.localStorage['spacewar.tutorial']?
		window.menu.open()
		window.localStorage['spacewar.tutorial'] = true

	# Use the game event handler.
	setInputHandlers()

	renderLoop(update, window.showFPS)

setInputHandlers = () ->
	# Send key presses and key releases to the server.
	$(document).keydown ({keyCode}) ->
		if not window.keys[keyCode]? or window.keys[keyCode] is off
			window.keys[keyCode] = on
			window.socket.send
				type: 'key down'
				playerId: window.playerId
				key: keyCode

	$(document).keyup ({keyCode}) ->
		window.keys[keyCode] = off
		window.socket.send
			type: 'key up'
			playerId: window.playerId
			key: keyCode

renderLoop = (callback, showFPS) ->
	# RequestAnimationFrame API
	# http://paulirish.com/2011/requestanimationframe-for-smart-animating/
	requestAnimFrame = ( () ->
		window.requestAnimationFrame       ||
			window.webkitRequestAnimationFrame ||
			window.mozRequestAnimationFrame    ||
			window.oRequestAnimationFrame      ||
			window.msRequestAnimationFrame     ||
			(callback, element) ->
				window.setTimeout(callback, 1000 / 60) )()

	currentFPS = 0
	frameCount = 0
	lastFPSupdate = 0

	lastTime = 0

	render = (time) ->
		# Setup next update.
		requestAnimFrame(render)

		# For browsers which do not pass the time argument.
		time ?= (new Date).getTime()

		# Update FPS every second
		if (time - lastFPSupdate > 1000)
			currentFPS = frameCount
			frameCount = 0
			lastFPSupdate = time
			console.info(currentFPS) if showFPS

		# Pass current time and time since last update to callback.
		callback(time, time - lastTime)

		# Another frame blit you must.
		++frameCount

		# Update time of the last update.
		lastTime = time

	requestAnimFrame(render)

# Game loop!
update = (time, sinceUpdate) ->
	# Update time globals (poor kittens...).
	window.sinceLastUpdate = sinceUpdate
	window.now = time

	# Update and cleanup objects.
	for idx, obj of window.gameObjects
		obj.update()
		if obj.serverDelete and obj.clientDelete
			deleteObject idx

	# Draw scene.
	centerView()
	redraw(window.ctxt)

window.inView = (x, y) ->
	window.view.x <= x <= window.view.x + window.screen.w and
	window.view.y <= y <= window.view.y + window.screen.h

# Clear canvas and draw everything.
# Not efficient, but we don't have that many objects.
redraw = (ctxt) ->
	ctxt.clearRect(0, 0, window.screen.w, window.screen.h)
	ctxt.lineJoin = 'round'

	drawMapBounds(ctxt) if window.showMapBounds

	# Draw all objects.
	obj.draw(ctxt)	for idx, obj of window.gameObjects

	# Draw outside of the map bounds.
	drawInfinity ctxt

	# Draw UI
	drawRadar ctxt if window.localShip? and not window.localShip.isDead()

drawMapBounds = (ctxt) ->
	ctxt.save()
	ctxt.lineWidth = 2
	ctxt.strokeStyle = '#dae'
	ctxt.strokeRect(-window.view.x, -window.view.y, window.map.w, window.map.h)
	ctxt.restore()

centerView = () ->
	if window.localShip?
		window.view.x = window.localShip.pos.x - window.screen.w/2
		window.view.y = window.localShip.pos.y - window.screen.h/2

drawRadar = (ctxt) ->
	for i, s of window.ships
		if i isnt window.shipId and not s.isDead()
			s.drawOnRadar(ctxt)

	for i, b of window.bonuses
		if b.state isnt 'dead'
			b.drawOnRadar(ctxt)

drawInfinity = (ctxt) ->
	# Can the player see the left, right, top and bottom voids?
	left = window.view.x < 0
	right = window.view.x > window.map.w - window.screen.w
	top = window.view.y < 0
	bottom = window.view.y > window.map.h - window.screen.h

	visibility = [[left and top,    top,    right and top]
	              [left,           	off,  right],
	              [left and bottom, bottom, right and bottom]]

	for i in [0..2]
		for j in [0..2]
			if visibility[i][j] is on
				for idx, obj of window.gameObjects
					offset =
						x: (j-1)*window.map.w
						y: (i-1)*window.map.h
					obj.draw(ctxt, offset)

	return true

onConnect = () ->
	info "Connected to server."

onDisconnect = () ->
	info "Aaargh! Disconnected!"

newObject = (i, type, obj) ->
	switch type
		when 'ship'
			window.ships[i] = new Ship(obj)
		when 'bullet'
			new Bullet(obj)
		when 'mine'
			new Mine(obj)
		when 'EMP'
			new EMP(obj)
		when 'bonus'
			window.bonuses[i] = new Bonus(obj)
		when 'planet'
			new Planet(obj)

deleteObject = (i) ->
	type = window.gameObjects[i].type

	switch type
		when 'ship'
			delete window.ships[i]
		when 'bonus'
			delete window.bonuses[i]

	delete window.gameObjects[i]

onMessage = (msg) ->
	switch msg.type

		# When receiving world update data.
		when 'objects update'
			for i, obj of msg.objects
				if not window.gameObjects[i]?
					window.gameObjects[i] = newObject(i, obj.type, obj)
				else
					window.gameObjects[i].serverUpdate(obj)

		# When receiving our id from the server.
		when 'connected'
			window.playerId = msg.playerId

			window.menu.sendPreferences()

			window.socket.send
				type: 'create ship'
				playerId: window.playerId

		# When receiving our id from the server.
		when 'ship created'
			window.shipId = msg.shipId
			window.localShip = window.gameObjects[window.shipId]
			go()

		# When another player leaves.
		when 'player quits'
			delete window.ships[msg.shipId]
			delete window.gameObjects[msg.shipId]
			info 'Player '+msg.playerId+' quits'

	return true
