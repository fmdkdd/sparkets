# Server
window.socket = null

# Graphics
window.ctxt = null
window.canvasSize = {w: 0, h: 0}
window.map = null
window.view = {x: 0, y: 0}

# Time
window.now = null
window.sinceLastUpdate = null

window.planetColor = [209,29,61]
window.maxBulletLength = 15

# Game logic
window.explosionDuration = 1000

window.playerId = null
window.shipId = null
window.localShip = null

window.ships = {}
window.bonuses = {}

window.gameObjects = {}

window.effects = []

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
	window.socket = io.connect()
	window.socket = window.socket.socket.of(window.location.hash.substring(1))
	window.socket.on 'connect', onConnect
	window.socket.on 'connected', onConnected
	window.socket.on 'objects update', onObjectsUpdate
	window.socket.on 'ship created', onShipCreated
	window.socket.on 'player quits', onPlayerQuits
	window.socket.on 'game end', onGameEnd
	window.socket.on 'disconnect', onDisconnect

	# Setup canvas.
	window.ctxt = document.getElementById('canvas').getContext('2d')

	# Setup window resizing event.
	$(window).resize (event) ->
		window.canvasSize.w = document.getElementById('canvas').width = window.innerWidth
		window.canvasSize.h = document.getElementById('canvas').height = window.innerHeight
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
			window.socket.emit 'key down',
				playerId: window.playerId
				key: keyCode

		# Open/Close the menu when 'M' is pressed.
		if keyCode is 77
			window.menu.toggle()

	$(document).keyup ({keyCode}) ->
		window.keys[keyCode] = off
		window.socket.emit 'key up',
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
	for id, obj of window.gameObjects
		obj.update()
		if obj.serverDelete and obj.clientDelete
			deleteObject id

	# Update and cleanup visual effects.
	for i in [0...window.effects.length]
		e = window.effects[i]
		# Splicing dead effects decrease the array size,
		# but effects.lengh is only checked at the start.
		if e?
			e.update()
			if e.deletable()
				window.effects.splice(i, 1)

	# Draw scene.
	redraw(window.ctxt)

window.boxInView = (x, y, r) ->
	window.inView(x-r, y-r) or window.inView(x-r, y+r) or
		window.inView(x+r, y-r) or window.inView(x+r, y+r)

window.inView = (x, y) ->
	window.view.x <= x <= window.view.x + window.canvasSize.w and
		window.view.y <= y <= window.view.y + window.canvasSize.h

# Clear canvas and draw everything.
# Not efficient, but we don't have that many objects.
redraw = (ctxt) ->
	ctxt.clearRect(0, 0, window.canvasSize.w, window.canvasSize.h)

	# Draw everything centered around the player.
	centerView()
	ctxt.save()
	ctxt.translate(-view.x, -view.y)

	drawMapBounds(ctxt) if window.showMapBounds

	# Draw all objects.
	for idx, obj of window.gameObjects
		drawObject(ctxt, obj) if obj.inView()

	# Draw all visual effects.
	for e in window.effects
		e.draw(ctxt) if e.inView()

	# Draw outside of the map bounds.
	drawInfinity ctxt

	# View translation doesn't apply to UI.
	ctxt.restore()

	# Draw UI
	drawRadar(ctxt) if window.localShip? and window.localShip.state is 'alive'

drawObject = (ctxt, obj, offset) ->
	ctxt.save()
	obj.draw(ctxt, offset)
	ctxt.restore()
	obj.drawHitbox(ctxt) if window.showHitCircles

drawMapBounds = (ctxt) ->
	ctxt.save()
	ctxt.lineWidth = 2
	ctxt.strokeStyle = '#dae'
	ctxt.strokeRect(0, 0, window.map.w, window.map.h)
	ctxt.restore()

centerView = () ->
	if window.localShip?
		window.view.x = window.localShip.pos.x - window.canvasSize.w/2
		window.view.y = window.localShip.pos.y - window.canvasSize.h/2

drawRadar = (ctxt) ->
	for id, ship of window.ships
		if id isnt window.shipId and ship.state isnt 'dead'
			ctxt.save()
			ship.drawOnRadar(ctxt)
			ctxt.restore()

	for id, bonus of window.bonuses
		if bonus.state isnt 'dead'
			ctxt.save()
			bonus.drawOnRadar(ctxt)
			ctxt.restore()

drawInfinity = (ctxt) ->
	# Can the player see the left, right, top and bottom voids?
	left = window.view.x < 0
	right = window.view.x > window.map.w - window.canvasSize.w
	top = window.view.y < 0
	bottom = window.view.y > window.map.h - window.canvasSize.h

	visibility = [[left and top,    top,    right and top]
	              [left,           	off,  right],
	              [left and bottom, bottom, right and bottom]]

	for i in [0..2]
		for j in [0..2]
			if visibility[i][j] is on
				# Translate to the adequate quadrant.
				offset =
					x: (j-1)*window.map.w
					y: (i-1)*window.map.h

				ctxt.save()
				ctxt.translate(offset.x, offset.y)

				# Draw all visible objects in it.
				for id, obj of window.gameObjects
					drawObject(ctxt, obj, offset) if obj.inView(offset)

				# Draw all visible effects
				for e in window.effects
					e.draw(ctxt, offset) if e.inView(offset)

				# Quadrant is done drawing.
				ctxt.restore()

	return true

onConnect = () ->
	console.info "Connected to server."

onDisconnect = () ->
	console.info "Aaargh! Disconnected!"

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
		when 'moon'
			new Planet(obj)

deleteObject = (id) ->
	type = window.gameObjects[id].type

	switch type
		when 'ship'
			delete window.ships[id]
		when 'bonus'
			delete window.bonuses[id]

	delete window.gameObjects[id]

# When receiving world update data.
onObjectsUpdate = (data) ->
	for id, obj of data.objects
		if not window.gameObjects[id]?
			window.gameObjects[id] = newObject(id, obj.type, obj)
		else
			window.gameObjects[id].serverUpdate(obj)

# When receiving our id from the server.
onConnected = (data) ->
	window.playerId = data.playerId

	# Copy useful game preferences from the server.
	window.map = data.serverPrefs.mapSize
	window.minPower = data.serverPrefs.ship.minPower
	window.maxPower = data.serverPrefs.ship.maxPower
	window.cannonCooldown = data.serverPrefs.ship.cannonCooldown

	window.menu.sendPreferences()

	window.socket.emit 'create ship',
		playerId: window.playerId

# When receiving our id from the server.
onShipCreated = (data) ->
	window.shipId = data.shipId
	window.localShip = window.gameObjects[window.shipId]
	go()

# When another player leaves.
onPlayerQuits = (data) ->
	deleteObject data.shipId

onGameEnd = () ->
	window.menu.open()
