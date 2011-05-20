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

		# Fade-in when the user clicks anywhere.
		$(document).click (event) =>
			if @isOpen() then @close() else @open()

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

	open: () ->
		@menu.removeClass('hidden')
		@menu.addClass('visible')

		@nameField.focus()

	close: () ->
		@menu.removeClass('visible')
		@menu.addClass('hidden')

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
		minRadius = 60
		maxLum = 80
		minLum = 30

		dx = @wheelBox.width()/2 - (event.pageX - @wheelBox.offset().left)
		dy = @wheelBox.height()/2 - (event.pageY - @wheelBox.offset().top)

		# Put the cursor at the click position.
		cursor = $('#colorCursor')
		cursor.css('display', 'block')
		cursor.offset({top: event.pageY-@colorCursor.height()/2, left: event.pageX-@colorCursor.width()/2})

		h = Math.atan2(dx, dy)
		h += 2*Math.PI if h < 0
		h =  Math.floor(h * 180/Math.PI)

		d = distance(event.pageX, event.pageY, @wheelBox.offset().left+100, @wheelBox.offset().top+100)
		l = Math.round(minLum + (maxRadius-d)/(maxRadius-minRadius)*(maxLum-minLum))

		return [h, 60, l]
