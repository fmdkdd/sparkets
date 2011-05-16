# Server
port = 12345
socket = {}

# Graphics
ctxt = null
screen = {w: 0, h: 0}
map = {w: 2000, h: 2000}
view = {x: 0, y: 0}

# Time
now = null
sinceLastUpdate = null

planetColor = '209,29%,61%'
maxBulletLength = 15

# Game logic
minPower = 1.3
maxPower = 3
maxExploFrame = 50
maxBullets = 10
cannonCooldown = 20

playerId = null
shipId = null
localShip = null

ships = {}
bonuses = {}

gameObjects = {}

keys = {}

# user preferences
displayNames = no

# Debugging
showHitCircles = no

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

	# Let the menu out when the user clicks anywhere.
	$(document).click (event) =>
		$('#menu').toggleClass('hidden visible')

		if $('#menu').attr('class') is 'visible'
			$('#name').focus()
		else
			$('#name').blur()

	# Do not propagate a click event when the user clicked on the menu.
	$('#menu').click (event) =>
		event.stopPropagation()

	$('#colorwheel').click (event) =>
		maxRadius = 100
		minRadius = 60
		maxLum = 80
		minLum = 20

		wheel = $('#colorwheel')
		dx = wheel.width()/2 - (event.pageX - wheel.offset().left)
		dy = wheel.height()/2 - (event.pageY - wheel.offset().top)

		h = Math.atan2(dx, dy)
		h += 2*Math.PI if h < 0
		h =  Math.floor(h * 180/Math.PI)

		d = distance(event.pageX, event.pageY, wheel.offset().left+100, wheel.offset().top+100) 
		l = minLum + (d-minRadius)/(maxRadius-minRadius)*(maxLum-minLum);

		c = h + ',' + 100 + '%,' + l + '%'

		# Store the color in a hidden field.
		$('#color').val(c)
		$('h1').css('color', 'hsl('+c+')');

	# Send a message to the server when the user changes his preferences.
	$('#nameForm').submit (event) =>
		sendPreferences()
		saveLocalPreferences()
		event.preventDefault()

	# Toggle the name display option.
	$('#displayNames').change (event) ->
		displayNames = $(this).is(':checked')

sendPreferences = () ->
		color = $('#color').val() or null
		name = $('#name').val() or null

		socket.send
			type: 'prefs changed'
			playerId: playerId
			color: color
			name: name

# Store user preferences in the browser local storage.
saveLocalPreferences = () ->
	color =  $('#color').val() or null
	name =  $('#name').val() or null

	localStorage['spacewar.color'] = color if color?
	localStorage['spacewar.name'] = name if name?

	info 'Preferences saved.'

# Restores user preferences in the browser local storage.
restoreLocalPreferences = () ->
	color = localStorage['spacewar.color']
	name = localStorage['spacewar.name']

	# Fill the menu and send the preferences to the server.
	$('#color').val(color) if color?
	$('#name').val(name) if name?
	sendPreferences()

	info 'Preferences restored.' if color? or name?

# Setup input callbacks and launch game loop.
go = (id) ->
	playerId = id

	# Check if user preferences are stored locally.
	restoreLocalPreferences()

	$(document).keydown ({keyCode}) ->
		if not keys[keyCode]? or keys[keyCode] is off
			keys[keyCode] = on
			socket.send
				type: 'key down'
				playerId: playerId
				key: keyCode

	$(document).keyup ({keyCode}) ->
		keys[keyCode] = off
		socket.send
			type: 'key up'
			playerId: playerId
			key: keyCode

	update()

# Game loop!
update = () ->
	start = (new Date).getTime()

	# Update time globals (poor kittens...).
	sinceLastUpdate = start - now
	now = start

	# Update and cleanup objects.
	for idx, obj of gameObjects
		obj.update()
		if obj.serverDelete and obj.clientDelete
			deleteObject idx

	# Draw scene.
	centerView()
	redraw(ctxt)

	# Setup next update.
	diff = (new Date).getTime() - start
	setTimeout(update, 20-mod(diff, 20))

inView = (x, y) ->
	view.x <= x <= view.x + screen.w and
	view.y <= y <= view.y + screen.h

# Clear canvas and draw everything.
# Not efficient, but we don't have that many objects.
redraw = (ctxt) ->
	ctxt.clearRect(0, 0, screen.w, screen.h)
	ctxt.lineJoin = 'round'

	# Draw all objects.
	obj.draw(ctxt)	for idx, obj of gameObjects

	# Draw outside of the map bounds.
	drawInfinity ctxt

	# Draw UI
	drawRadar ctxt if localShip? and not localShip.isDead()

centerView = () ->
	if localShip?
		view.x = localShip.pos.x - screen.w/2
		view.y = localShip.pos.y - screen.h/2

drawRadar = (ctxt) ->
	for i, s of ships
		if i isnt shipId and not s.isDead()
			s.drawOnRadar(ctxt)

	for i, b of bonuses
		if b.state isnt 'dead'
			b.drawOnRadar(ctxt)

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
	info "Connected to server."

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
		when 'EMP'
			new EMP(obj)
		when 'bonus'
			bonuses[i] = new Bonus(obj)
		when 'planet'
			new Planet(obj)

deleteObject = (i) ->
	type = gameObjects[i].type

	switch type
		when 'ship'
			delete ships[i]
		when 'bonus'
			delete bonuses[i]

	delete gameObjects[i]

onMessage = (msg) ->
	switch msg.type

		# When receiving world update data.
		when 'objects update'
			for i, obj of msg.objects
				if not gameObjects[i]?
					gameObjects[i] = newObject(i, obj.type, obj)
				else
					gameObjects[i].serverUpdate(obj)

		# When receiving our id from the server.
		when 'connected'
			shipId = msg.shipId
			localShip = gameObjects[shipId]
			go(msg.playerId)

		# When another player leaves.
		when 'player quits'
			delete ships[msg.shipId]
			delete gameObjects[msg.shipId]
			info 'Player '+msg.playerId+' quits'

	return true
