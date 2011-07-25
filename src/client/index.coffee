class Index
	constructor: () ->

		# Server.
		@socket = null

		@gameListRegExp = null

		# Connect to server and set callbacks.
		@socket = io.connect()

		# Grab the game list every minute.
		setInterval( (() =>
			@socket.emit('get game list')), 60 * 1000)

		# Fetch the game list at first connection.
		@socket.on 'connect', () =>
			@socket.emit 'get game list'

		# Update list of running games.
		@socket.on 'game list', (data) =>
			$('#gameList').empty()

			minutesLeft = (start, duration) ->
				new Date(duration - (Date.now() - start)).getMinutes()

			for id, game of data
				href = '/play/#' + id
				$('#gameList').append('<tr>
					<td><a href="' + href + '">' + id + '</a></td>
					<td>' + game.players + '</td>
					<td>' + minutesLeft(game.startTime, game.duration * 60 * 1000) + ' min</td>
					</tr>')

			idList = Object.keys(data)
			if idList.length > 0
				@gameListRegexp = new RegExp('^(' + idList.join('|') + '$)')
			else
				@gameListRegexp = null

			@socket.on 'game already exists', () ->
				$('#id-error').html('Name already exists')

		@setupPage()

	setupPage: () ->

		# Add selection boxes.
		@selectionBoxes = []
		@selectionBoxes.push new SelectionBox($('#map'), 'mapSize', ['tiny', 'small', 'medium', 'large', 'epic'], 2)
		@selectionBoxes.push new SelectionBox($('#map'), 'planetCount', ['none', 'scarce', 'regular', 'abudantly'], 2)

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
				xOff = left if xOff < left
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

		$('input[name="id"]').keyup (event) ->
			if @gameListRegexp? and @.value.match(@gameListRegexp)
				$('#id-error').html('Name already exists')
				$('input[value="Create"]').attr('disabled', 'disabled')
			else
				$('#id-error').html('')
				$('input[value="Create"]').removeAttr('disabled')

		$('#createForm').submit (event) =>
			event.preventDefault()
			data = @gatherValues()

			# Prepare game options.
			opts =
				id: data[0].id
				prefs: data[0]
				presets: data[1]
			delete data.id

			@socket.emit 'create game', opts, () ->
				# Clear and unfocus game name input on creation.
				nameInput = $('#createForm input[name="id"]')
				nameInput.val('')
				nameInput.blur()

		$('#createForm ul.collapse h3').click (event) ->
			$(@).next().toggle()

	gatherValues: () ->
		insert = (obj, name, val) ->
			[prop, rest...] = name.split('.')

			if rest.length > 0
				obj[prop] = {} if not obj[prop]?
				insert(obj[prop], rest.join('.'), val)
			else
				obj[name] = val

		prefs = {}
		for input in $('#createForm').find('input')
			if input.name? and input.value?
				switch input.type
					when 'text'
						insert(prefs, input.name, input.value)
					when 'range'
						insert(prefs, input.name, parseFloat(input.value))

		presets = {}
		for sb in @selectionBoxes
			presets[sb.name] = sb.value()

		return [prefs, presets]

# Entry point.
$(document).ready () ->
	window.index = new Index()
