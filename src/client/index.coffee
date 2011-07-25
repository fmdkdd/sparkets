class Index
	constructor: () ->

		# Server.
		@socket = null

		# Regexp for game name validation.
		@gameListRegexp = null

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

		# Add ranges with tooltips.
		new Range($('#gamePrefs ul li:nth-child(1)'), 'Duration (min)', 'duration', 3, 20, 1, 5)

		new Range($('#mapPrefs ul li:nth-child(2)'), 'Planet count', 'planetCount', 10, 50, 1, 20)

		new Range($('#bonusPrefs ul li:nth-child(1)'), 'Drop wait (ms)', 'bonus.waitTime', 1000, 10000, 1000, 5000)
		new Range($('#bonusPrefs ul li:nth-child(2)'), 'Activation wait (ms)', 'bonus.states.incoming.countdown', 500, 5000, 500, 2000)
		new Range($('#bonusPrefs ul li:nth-child(3)'), 'Max allowed', 'bonus.maxCount', 0, 20, 1, 10)
		new Range($('#bonusPrefs ul li:nth-child(4)'), 'Mines in bonus', 'bonus.mine.mineCount', 1, 10, 1, 2)

		new Range($('#bonusAppearancePrefs ul li:nth-child(1)'), 'Mines weight', 'bonus.bonusType.mine.weight', 0, 10, 1, 3)
		new Range($('#bonusAppearancePrefs ul li:nth-child(2)'), 'Boost weight', 'bonus.bonusType.boost.weight', 0, 10, 1, 3)
		new Range($('#bonusAppearancePrefs ul li:nth-child(3)'), 'EMP weight', 'bonus.bonusType.EMP.weight', 0, 10, 1, 3)
		new Range($('#bonusAppearancePrefs ul li:nth-child(4)'), 'Stealth weight', 'bonus.bonusType.stealth.weight', 0, 10, 1, 3)

		new Range($('#shipPrefs ul li:nth-child(1)'), 'Speed', 'ship.speed', 0.1, 1, 0.1, 0.3)
		new Range($('#shipPrefs ul li:nth-child(2)'), 'Friction Decay', 'ship.frictionDecay', 0, 1, 0.01, 0.97)

		new Range($('#botPrefs ul li:nth-child(1)'), 'Count', 'bot.count', 0, 10, 1, 1)	

		# Add selection boxes.
		@selectionBoxes = []
		@selectionBoxes.push new SelectionBox($('#mapPrefs ul li:nth-child(1)'), 'mapSize', ['tiny', 'small', 'medium', 'large', 'epic'], 2)
		#@selectionBoxes.push new SelectionBox($('#mapPrefs ul li:nth-child(2)'), 'planetCount', ['none', 'scarce', 'regular', 'abudantly'], 2)

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
