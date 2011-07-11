window.socket = {}

window.socket = io.connect()
window.socket.on 'connect', () ->
	window.socket.emit 'get game list'

window.socket.on 'game list', (data) ->
	# Update list of running games.
	$('#gameList').empty()

	for id in data.list
		href = '/play/#' + id
		$('#gameList').append('<li><a href="' + href + '">' + id + '</a></li>')

	window.gameListRegexp = new RegExp(data.list.join('|'))

window.socket.on 'game already exists', () ->
	$('#id-error').html('Name already exists')

# Setup form handler
$(document).ready () ->
	gatherValues = (form) ->
		insert = (obj, name, val) ->
			[prop, rest...] = name.split('.')

			if rest.length > 0
				obj[prop] = {} if not obj[prop]?
				insert(obj[prop], rest.join('.'), val)

			else
				obj[name] = val

		values = {}

		for input in $(form).find('input')
			if input.name? and input.value?
				switch input.type
					when 'text'
						insert(values, input.name, input.value)
					when 'range'
						insert(values, input.name, parseFloat(input.value))

		return values


	$('input[name="id"]').keyup (event) ->
		if @.value.match(window.gameListRegexp)
			$('#id-error').html('Name already exists')
		else
			$('#id-error').html('')

	$('#createForm').submit (event) ->
		event.preventDefault()
		prefs = gatherValues(@)

		window.socket.emit 'create game', prefs, () ->
			# Clear and unfocus game name input on creation.
			nameInput = $('input[name="id"]')
			nameInput.val('')
			nameInput.blur()

	$('ul.collapse h3').click (event) ->
		$(@).next().toggle()

	# Hide ship prefs menu at start.
	$('#shipPrefs').next().hide()

	# Tooltip to indicate current value for range input.
	# Created at mouse down and detached on mouse up, the tooltip
	# follows the mouse pointer on mouse move.
	attachTooltip = (element) ->
		tooltip = null

		updateTooltip = (val) ->
			# Delay tooltip value update after the value has been updated
			# in the browser. Otherwise, clicking away from the slider
			# cursor will move the cursor to the mouse but @.value won't
			# be updated.
			setTimeout( (() ->
				tooltip.innerHTML = val ), 1)

		# Inexact floats have to be pretty-printed. The plan is to
		# convert them using toFixed(2) for 2 decimal places.
		# Integers stay as they are.
		prettyNumber = (str) ->
			isInt = (string) ->
				parseInt(string) == parseFloat(string)

			if isInt(str)
				str
			else
				str = parseFloat(str).toFixed(2)

		element.mousedown (event) ->
			return if event.which isnt 1

			# With enough clicking around you can avoid a mouse up
			# event. Clear any previously created tooltip to avoid
			# duplicates.
			$(tooltip).detach() if tooltip?
			tooltip = document.createElement('span')
			tooltip.className = 'tooltip'

			$(tooltip).css('position', 'absolute')
			$(tooltip).css('top', $(@).offset().top - $(@).height())
			$(tooltip).css('left', event.pageX)
			$(@).after(tooltip)

			updateTooltip(prettyNumber(@.value))

		# Update tooltip value and follow pointer.
		element.mousemove (event) ->
			return if event.which isnt 1
			return if not tooltip?

			# Constrain to input element width.
			xOff = event.pageX
			left = $(@).offset().left
			xOff = offset.left if xOff < left
			right = left + $(@).innerWidth()
			xOff = right if xOff > right

			$(tooltip).css('left', xOff)

			updateTooltip(prettyNumber(@.value))

		# Delete tooltip.
		element.mouseup (event) ->
			return if event.which isnt 1
			return if not tooltip?

			$(tooltip).detach()

	$('input[type="range"]').each () ->
		attachTooltip($(@))
