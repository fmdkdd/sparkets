class Menu
	constructor: () ->

		@menu = $('#menu')
		@wheelBox = $('#colorWheelBox')
		@shipPreview = $('#shipPreview')
		@wheel = $('#colorWheel')
		@colorCursor = $('#colorCursor')
		@form = $('#nameForm')
		@nameField = $('#name')
		@displayNamesCheck = $('#displayNamesCheck')
		@closeButton = $('#closeButton')

		@currentColor = null

		# Stop the event propagation when a click on the menu is detected.
		$('#menu').click (event) =>
			event.stopPropagation() if $('#menu').attr('class') is 'visible'

		@wheelBox.click (event) =>
			@currentColor = c = @readColor(event)

			# Change the color of the center of the wheel.
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
		@displayNamesCheck.change (event) ->
			displayNames = @displayNamesCheck.is(':checked')

		# Close the menu.
		@closeButton.click (event) =>
			if @isOpen()
				@close()
				event.stopPropagation()

	focusInputs: () ->
	
		# Clear all event handlers attached to the document.
		$(document).unbind()

		# Close the menu when a click is detected outside of it.
		$(document).click (event) =>
			@close()
		@menu.click (event) =>
			event.stopPropagation()

		$(document).keyup ({keyCode}) =>
			switch keyCode

				# Close the menu when the Escape key is pressed.
				when 27
					@close()

	open: () ->
		@menu.removeClass('hidden')
		@menu.addClass('visible')

		# Use the menu event handler.
		@focusInputs()

		@nameField.focus()

	close: () ->
		@menu.removeClass('visible')
		@menu.addClass('hidden')

		# Use the game event handler.
		focusInputs()

		@nameField.blur()

	isOpen: () ->
		@menu.hasClass('visible')

	# Send user preferences to the server.
	sendPreferences: () ->
		color = @currentColor
		name = @nameField.val() if @nameField.val().length > 0

		socket.send
			type: 'prefs changed'
			playerId: playerId
			color: color
			name: name

	# Store user preferences in the browser local storage.
	saveLocalPreferences: () ->
		localStorage['spacewar.color'] = @currentColor if @currentColor?
		localStorage['spacewar.name'] = @nameField.val() if @nameField.val().length > 0

		info 'Preferences saved.'

	# Restores user preferences from browser local storage.
	restoreLocalPreferences: () ->
		@currentColor = localStorage['spacewar.color'].split(',') if localStorage['spacewar.color']?
		@nameField.val(localStorage['spacewar.name']) if localStorage['spacewar.name']

		@sendPreferences()

		info 'Preferences restored.'

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
