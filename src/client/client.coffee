class Client
	constructor: () ->

		# Server
		@socket = null

		# Graphics
		@ctxt = document.getElementById('canvas').getContext('2d')
		@canvasSize = {w: 0, h: 0}
		@mapSize = null
		@view = {x: 0, y: 0}
		@mouse = {x: 0, y: 0}

		@spriteManager = new SpriteManager()

		# Time
		@now = null
		@sinceLastUpdate = null

		@playerId = null
		@shipId = null
		@localShip = null

		@gameObjects = {}
		@ships = {}
		@bonuses = {}

		@effects = []

		@keys = {}

		# User preferences
		@displayNames = no

		# Game logic
		@maxBulletLength = 15

		# Debugging
		@showHitBoxes = no
		@showMapBounds = no
		@showFPS = no

		@menu = new Menu(@)
		@menu.restoreLocalPreferences()

		@chat = new Chat(@)

		# Connect to server and set callbacks.
		@socket = io.connect()
		@socket = @socket.socket.of(window.location.hash.substring(1))

		# Setup a connexion timeout to redirect to homepage in case of
		# nonexistent games.
		@connectionTimeout = setTimeout( ( () ->
			url = 'http://' + window.location.hostname + ':' + window.location.port
			window.location.replace(url)), 1500)

		# Bind socket events.
		@socket.on 'connect', () =>
			@onConnect()

			@socket.on 'connected', (data) =>
				@onConnected(data)

			@socket.on 'objects update', (data) =>
				@onObjectsUpdate(data)

			@socket.on 'ship created', (data) =>
				@onShipCreated(data)

			@socket.on 'player says', (data) =>
				@onPlayerMessage(data)

			@socket.on 'player quits', (data) =>
				@onPlayerQuits(data)

			@socket.on 'game end', (data) =>
				@onGameEnd(data)

			@socket.on 'disconnect', (data) =>
				@onDisconnect(data)

		# Setup window resizing event.
		$(window).resize (event) =>
			@canvasSize.w = document.getElementById('canvas').width = window.innerWidth
			@canvasSize.h = document.getElementById('canvas').height = window.innerHeight
		$(window).resize()

	# Setup input callbacks and launch game loop.
	go: () ->
		# Show the menu the first time.
		if not window.localStorage['spacewar.tutorial']?
			@menu.open()
			window.localStorage['spacewar.tutorial'] = true

		# Use the game event handler.
		@setInputHandlers()

		@renderLoop(@showFPS)

	setInputHandlers: () ->
		# Space, left, up, right, A, Z
		processedKeys = [32, 37, 38, 39, 65, 90]

		# Send key presses and key releases to the server.
		$(document).keydown (event) =>
			return unless event.keyCode in processedKeys

			event.preventDefault()

			if not @keys[event.keyCode]? or @keys[event.keyCode] is off
				@keys[event.keyCode] = on
				@socket.emit 'key down',
					playerId: @playerId
					key: event.keyCode

		$(document).keyup ({keyCode}) =>
			return unless keyCode in processedKeys

			@keys[keyCode] = off
			@socket.emit 'key up',
				playerId: @playerId
				key: keyCode

		# Track mouse position.
		$(document).mousemove ({pageX, pageY}) =>
			@mouse.x = pageX
			@mouse.y = pageY

		# Let the player move the camera around when his ship died.
		$(document).mousedown () =>
			if @localShip.state in ['dead', 'ready']
				recenter = () =>
					# Move the camera towards the position of the mouse.
					center = {x: @canvasSize.w/2, y: @canvasSize.h/2}
					@view.x += (@mouse.x-center.x)/50
					@view.y += (@mouse.y-center.y)/50

					# Warp the camera.
					s = @mapSize
					if @view.x < 0 then @view.x = s
					if @view.x > s then @view.x = 0
					if @view.y < 0 then @view.y = s
					if @view.y > s then @view.y = 0

				@mouseDownInterval = setInterval(recenter, 5)

		$(document).mouseup () =>
			clearInterval(@mouseDownInterval)

	renderLoop: (showFPS) ->

		# RequestAnimationFrame API
		# http://paulirish.com/2011/requestanimationframe-for-smart-animating/
		requestAnimFrame = ( () =>
			window.requestAnimationFrame       or
			window.webkitRequestAnimationFrame or
			window.mozRequestAnimationFrame    or
			window.oRequestAnimationFrame      or
			window.msRequestAnimationFrame     or
			(callback, element) -> setTimeout(callback, 1000 / 60) )()

		currentFPS = 0
		frameCount = 0
		lastFPSupdate = 0
		lastTime = 0

		render = (time) =>
			# Setup next update.
			requestAnimFrame(render)

			# For browsers which do not pass the time argument.
			time ?= Date.now()

			# Update FPS every second
			if (time - lastFPSupdate > 1000)
				currentFPS = frameCount
				frameCount = 0
				lastFPSupdate = time
				console.info(currentFPS) if showFPS

			# Pass current time and time since last update to callback.
			@update(time, time - lastTime)

			# Another frame blit you must.
			++frameCount

			# Update time of the last update.
			lastTime = time

		requestAnimFrame(render)

	# Game loop!
	update: (time, sinceUpdate) ->

		# Update time variables.
		@sinceLastUpdate = sinceUpdate
		@now = time

		# Update and cleanup objects.
		for id, obj of @gameObjects
			obj.update()
			if obj.serverDelete and obj.clientDelete
				@deleteObject id

		# Update and cleanup visual effects.
		effects = []
		for e in @effects
			e.update()
			if not e.deletable()
				effects.push e
		@effects = effects

		# Draw scene.
		@redraw(@ctxt)

	boxInView: (x, y, r) ->
		@inView(x-r, y-r) or
		@inView(x-r, y+r) or
		@inView(x+r, y-r) or
		@inView(x+r, y+r)

	inView: (x, y) ->
		@view.x <= x <= @view.x + @canvasSize.w and
		@view.y <= y <= @view.y + @canvasSize.h

	# Clear canvas and draw everything.
	# Not efficient, but we don't have that many objects.
	redraw: (ctxt) ->
		ctxt.clearRect(0, 0, @canvasSize.w, @canvasSize.h)

		# Draw everything centered around the player when he's alive.
		unless @localShip.state in ['dead', 'ready']
			@centerView(@localShip)

		ctxt.save()
		ctxt.translate(-@view.x, -@view.y)

		@drawMapBounds(ctxt) if @showMapBounds

		# Draw all objects.
		for idx, obj of @gameObjects
			@drawObject(ctxt, obj) if obj.inView()

		# Draw all visual effects.
		for e in @effects
			e.draw(ctxt) if e.inView()

		# Draw outside of the map bounds.
		@drawInfinity ctxt

		# View translation doesn't apply to UI.
		ctxt.restore()

		# Draw UI
		@drawRadar(ctxt) if @localShip? and @localShip.state is 'alive'

	drawObject: (ctxt, obj, offset) ->
		ctxt.save()
		obj.draw(ctxt, offset)
		ctxt.restore()
		if @showHitBoxes
			ctxt.save()
			obj.drawHitbox(ctxt)

			# Draw bounding box
			ctxt.strokeStyle = 'blue'
			r = obj.boundingBox.radius
			ctxt.strokeRect(obj.boundingBox.x - r, obj.boundingBox.y - r, 2*r, 2*r)
			ctxt.restore()

	drawMapBounds: (ctxt) ->
		ctxt.save()
		ctxt.lineWidth = 2
		ctxt.strokeStyle = '#dae'
		ctxt.strokeRect(0, 0, @mapSize, @mapSize)
		ctxt.restore()

	centerView: (obj) ->
		@view.x = obj.pos.x - @canvasSize.w/2
		@view.y = obj.pos.y - @canvasSize.h/2

	drawRadar: (ctxt) ->
		for id, ship of @ships
			unless id is @shipId or ship.state in ['dead', 'ready', 'spawned']
				ctxt.save()
				ship.drawOnRadar(ctxt)
				ctxt.restore()

		for id, bonus of @bonuses
			if bonus.state isnt 'dead'
				ctxt.save()
				bonus.drawOnRadar(ctxt)
				ctxt.restore()

		true

	drawInfinity: (ctxt) ->

		# Can the player see the left, right, top and bottom voids?
		left = @view.x < 0
		right = @view.x > @mapSize - @canvasSize.w
		top = @view.y < 0
		bottom = @view.y > @mapSize - @canvasSize.h

		visibility = [[left and top,    top,    right and top]
		              [left,           	off,  right],
	  	            [left and bottom, bottom, right and bottom]]

		for i in [0..2]
			for j in [0..2]
				if visibility[i][j] is on
					# Translate to the adequate quadrant.
					offset =
						x: (j-1)*@mapSize
						y: (i-1)*@mapSize

					ctxt.save()
					ctxt.translate(offset.x, offset.y)

					# Draw all visible objects in it.
					for id, obj of @gameObjects
						@drawObject(ctxt, obj, offset) if obj.inView(offset)

					# Draw all visible effects
					for e in @effects
						e.draw(ctxt, offset) if e.inView(offset)

					# Quadrant is done drawing.
					ctxt.restore()

		return true

	newObject: (id, type, obj) ->
		switch type
			when 'ship'
				@ships[id] = new Ship(@, obj)
			when 'bullet'
				new Bullet(@, obj)
			when 'mine'
				new Mine(@, obj)
			when 'shield'
				new Shield(@, obj)
			when 'bonus'
				@bonuses[id] = new Bonus(@, obj)
			when 'planet'
				new Planet(@, obj)
			when 'moon'
				new Planet(@, obj)
			when 'rope'
				new Rope(@, obj)
			when 'tracker'
				new Tracker(@, obj)

	deleteObject: (id) ->
		type = @gameObjects[id].type

		switch type
			when 'ship'
				delete @ships[id]
			when 'bonus'
				delete @bonuses[id]

		delete @gameObjects[id]

	closestGhost: (sourcePos, targetPos) ->
		bestPos = null
		bestDistance = Infinity

		for i in [-1..1]
			for j in [-1..1]
				ox = targetPos.x + i * @mapSize
				oy = targetPos.y + j * @mapSize
				d = utils.distance(sourcePos.x, sourcePos.y, ox, oy)
				if d < bestDistance
					bestDistance = d
					bestPos = {x: ox, y: oy}

		return bestPos

	onConnect: () ->
		console.info "Connected to server."
		clearTimeout(@connectionTimeout)

	onDisconnect: () ->
		console.info "Aaargh! Disconnected!"

	# When receiving our id from the server.
	onConnected: (data) ->
		@playerId = data.playerId
		@gameStartTime = data.startTime

		# Copy useful game preferences from the server.
		@mapSize = data.serverPrefs.mapSize
		@minPower = data.serverPrefs.ship.minPower
		@maxPower = data.serverPrefs.ship.maxPower
		@gameDuration = data.serverPrefs.duration
		@cannonCooldown = data.serverPrefs.ship.cannonCooldown

		@menu.sendPreferences()

		@socket.emit 'create ship',
			playerId: @playerId

	onShipCreated: (data) ->
		@shipId = data.shipId
		@localShip = @gameObjects[@shipId]

		# Set the color of the ship preview in menu to our ship color.
		@menu.currentColor = @localShip.color
		@menu.updatePreview(@localShip.color)

		@go()

	# When receiving world update data.
	onObjectsUpdate: (data) ->
		for id, obj of data.objects
			if not @gameObjects[id]?
				@gameObjects[id] = @newObject(id, obj.type, obj)
			else
				@gameObjects[id].serverUpdate(obj)

		if data.events?
			for e in data.events
				@handleEvent(e)

	handleEvent: (event) ->
		switch event.type
			when 'ship exploded'
				@gameObjects[event.id].explosionEffect()
				@gameObjects[event.id].dislocationEffect()
				@chat.receiveEvent(event)

			when 'ship boosted'
				@gameObjects[event.id].boostEffect()

			when 'mine exploded'
				@gameObjects[event.id].explosionEffect()

			when 'bonus used'
				@gameObjects[event.id].openingEffect()

			when 'bonus exploded'
				@gameObjects[event.id].openingEffect()
				@gameObjects[event.id].explosionEffect()

			when 'rope exploded'
				@gameObjects[event.id].explosionEffect()

			when 'tracker activated'
				@gameObjects[event.id].trailEffect()
				@gameObjects[event.id].boostEffect()

			when 'tracker exploded'
				@gameObjects[event.id].explosionEffect()

			when 'EMP released'
				@gameObjects[event.id].EMPEffect()

	# When a player sent a chat message.
	onPlayerMessage: (data)->
		@chat.receiveMessage(data)

	# When another player leaves.
	onPlayerQuits: (data) ->
		@deleteObject data.shipId

	onGameEnd: () ->
		@gameEnded = yes
		@menu.open()

# Entry point.
$(document).ready () ->
	window.client = new Client()
