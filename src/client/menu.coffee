class Menu
	constructor: () ->

		@menu = $('#menu')
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
		@wheelBox.click (event) =>
			return if event.which is not 1 # Only left click triggers.

			@currentColor = c = @readColor(event)

			# Change the color of the ship preview.
			style = @shipPreview.attr('style')
			style = style.replace(/stroke: [^\n]+/,
				'stroke: hsl('+c[0]+','+c[1]+'%,'+c[2]+'%);')
			@shipPreview.attr('style', style)

		# Send users preferences and save them locally.
		@form.submit (event) =>
			@saveLocalPreferences()
			@sendPreferences()
			event.preventDefault()

		# Toggle the name display option.
		@displayNamesCheck.change (event) =>
			window.displayNames = @displayNamesCheck.is(':checked')

		# Close the menu.
		@closeButton.click (event) =>
			if @isOpen() and event.which is 1 # Left click
				@close()
				event.stopPropagation()

		# Toggle the menu when a left click is detected in the document.
		$(document).click (event) =>
			@toggle() if event.which is 1

		# But don't toggle if the click is inside the menu.
		# Clicking is expected on name input box and links.
		@menu.click (event) ->
			event.stopPropagation() if event.which is 1

		# Close the menu when the Escape key is pressed.
		$(document).keyup ({keyCode}) =>
			@toggle() if keyCode is 27

	toggle: () ->
		if @isOpen() then @close() else @open()

	open: () ->
		@updateScores()

		@menu.removeClass('hidden')
		@menu.addClass('visible')

	close: () ->
		@menu.removeClass('visible')
		@menu.addClass('hidden')

	isOpen: () ->
		@menu.hasClass('visible')

	# Send user preferences to the server.
	sendPreferences: () ->
		color = @currentColor
		name = @nameField.val() if @nameField.val().length > 0

		window.socket.emit 'prefs changed',
			playerId: playerId
			color: color
			name: name

	# Store user preferences in the browser local storage.
	saveLocalPreferences: () ->
		window.localStorage['spacewar.color'] = @currentColor if @currentColor?
		window.localStorage['spacewar.name'] = @nameField.val() if @nameField.val().length > 0

		console.info 'Preferences saved.'

	# Restores user preferences from browser local storage.
	restoreLocalPreferences: () ->
		if window.localStorage['spacewar.color']?
			@currentColor = window.localStorage['spacewar.color'].split(',')
		if window.localStorage['spacewar.name']
			@nameField.val(window.localStorage['spacewar.name'])

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

		d = distance(0, 0, dx, dy)

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

	updateScores: () ->
		@scoreTable.empty()

		scores = []
		for id, ship of window.ships
			scores.push
				name: ship.name or 'unnamed'
				color: ship.color
				deaths: ship.stats.deaths
				kills: ship.stats.kills

		# Sort scores.
		scores.sort( (a, b) -> b.kills - a.kills)

		for s in scores
			@scoreTable.append(
					'<tr><td><ul style="color:hsl(' + s.color[0] + ',' + s.color[1] + '%,' + s.color[2] + '%)"><li><span>' + s.name + '</span></li></ul></td>' +
					'<td>' +	s.deaths + '</td>' +
					'<td>' +	s.kills + '</td><tr>')

# Exports
window.Menu = Menu
