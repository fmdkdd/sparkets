class Menu
	constructor: (@client) ->

		@menu = $('section#menu')
		@closeButton = $('#closeButton')

		# Customization panel.
		@wheelBox = $('#colorWheelBox')
		@shipPreview = $('#shipPreview')
		@wheel = $('#colorWheel')
		@colorCursor = $('#colorCursor')
		@form = $('#nameForm')
		@nameField = $('#name')
		@displayNamesCheck = $('#displayNamesCheck')

		# Scores panel.
		@scoreTable = $('#scores table tbody')

		@currentColor = null

		@setInputHandlers()

	setInputHandlers: () ->
		pickColor = (event) =>
			@currentColor = @readColor(event)
			@updatePreview(@currentColor)

		@wheelBox.mousedown (event) =>
			return if event.which isnt 1 # Only left click triggers.

			event.preventDefault()
			pickColor(event)

			# Can hold mouse to choose color.
			@wheelBox.mousemove (event) =>
				return if event.which isnt 1 # Only left click triggers.

				event.preventDefault()
				pickColor(event)

		$(document).mouseup (event) =>
			return if event.which isnt 1 # Only left click triggers.

			# Mouse move can be triggered without any click.
			@wheelBox.unbind('mousemove')

		# Send users preferences and save them locally.
		@form.submit (event) =>
			@saveLocalPreferences()
			@sendPreferences()
			event.preventDefault()

		# Toggle the name display option.
		@displayNamesCheck.change (event) =>
			@client.displayNames = @displayNamesCheck.is(':checked')

		# Close the menu.
		@closeButton.click (event) =>
			if @isOpen() and event.which is 1 # Left click
				@close()
				event.stopPropagation()

		# Toggle the menu when M is pressed.
		$(document).keyup ({keyCode}) =>
			return if @client.chat.isOpen()

			# Check that we are not typing the letter M in the name field.
			else if keyCode is 77 and $('#customize input:focus').length is 0
				@toggle()

	toggle: () ->
		if @isOpen() then @close() else @open()

	open: () ->
		@updateScores()

		@updateTime()
		@clockInterval = setInterval( (() =>
			@updateTime()), 1000)

		@menu.removeClass('hidden')
		@menu.addClass('visible')

	close: () ->
		@menu.removeClass('visible')
		@menu.addClass('hidden')

		clearInterval(@clockInterval)

	isOpen: () ->
		@menu.hasClass('visible')

	# Send user preferences to the server.
	sendPreferences: () ->
		color = @currentColor
		name = @nameField.val() if @nameField.val().length > 0

		@client.socket.emit 'prefs changed',
			color: color
			name: name

	# Store user preferences in the browser local storage.
	saveLocalPreferences: () ->
		window.localStorage['sparkets.color'] = @currentColor if @currentColor?
		window.localStorage['sparkets.name'] = @nameField.val() if @nameField.val().length > 0

		console.info 'Preferences saved.'

	# Restores user preferences from browser local storage.
	restoreLocalPreferences: () ->
		if window.localStorage['sparkets.color']?
			@currentColor = window.localStorage['sparkets.color'].split(',')
		if window.localStorage['sparkets.name']
			@nameField.val(window.localStorage['sparkets.name'])

		console.info 'Preferences restored.'

	# Return the color chosen from the colorwheel.
	readColor: (event) ->
		maxRadius = 100
		minRadius = 50
		maxLum = 80
		minLum = 30

		center =
			x: @wheelBox.offset().left + @wheelBox.width()/2
			y: @wheelBox.offset().top + @wheelBox.height()/2

		dx = center.x - event.pageX
		dy = center.y - event.pageY

		h = Math.atan2(dx, dy)
		h += 2*Math.PI if h < 0
		hDeg = Math.round(h * 180/Math.PI)

		d = window.utils.distance(0, 0, dx, dy)

		# Clamp distance to colorwheel disc.
		d = Math.max(minRadius, Math.min(d, maxRadius))

		l = Math.round(minLum + (maxRadius-d)/(maxRadius-minRadius)*(maxLum-minLum))

		# Put the cursor at the clamped click position.
		x = center.x - Math.sin(h) * d
		y = center.y - Math.cos(h) * d

		cursor = $('#colorCursor')
		cursor.css('display', 'block')
		cursor.offset
			left: x - @colorCursor.width()/2
			top: y - @colorCursor.height()/2

		return [hDeg, 60, l]

	updatePreview: (color) ->
		# Change the color of the ship preview.
		style = @shipPreview.attr('style')

		style = style.replace(/stroke: [^\n]+/,
			'stroke: hsl('+color[0]+','+color[1]+'%,'+color[2]+'%);')

		@shipPreview.attr('style', style)

	updateScores: () ->
		@scoreTable.empty()

		scores = []
		for id, ship of @client.ships
			scores.push
				name: ship.name or 'unnamed'
				color: ship.color
				deaths: ship.stats.deaths
				kills: ship.stats.kills
				score: ship.stats.kills - ship.stats.deaths

		# Sort scores.
		scores.sort( (a, b) -> b.score - a.score)

		for i in [0...scores.length]
			s = scores[i]
			cssColor = 'hsl('+s.color[0]+','+s.color[1]+'%,'+s.color[2]+'%)'
			@scoreTable.append(
					'<tr><td>' + (i+1) + '</td>' +
					'<td><span class="colorBullet" style="background-color: ' + cssColor + '">&nbsp;</span>' + s.name + '</span></td>' +
					'<td>' +	s.deaths + '</td>' +
					'<td>' +	s.kills + '</td>' +
					'<td>' + s.score + '</td></tr>')

	updateTime: () ->
		if @client.gameEnded
			clearInterval(@clockInterval)
			$('#timeLeft').html("The game has ended!")
			return

		# Compute in ms since Epoch.
		elapsed = Date.now() - @client.gameStartTime
		remaining = @client.gameDuration * 60 * 1000 - elapsed

		# Use Date for conversion and pretty printing.
		timeLeft = new Date(remaining)

		pad = (n) ->
			if n < 10 then '0'+n else n

		$('#timeLeft').html(timeLeft.getMinutes() + ':' + pad(timeLeft.getSeconds()))

# Exports
window.Menu = Menu
