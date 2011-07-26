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

	presets:
		mapSize:
			'tiny': 1000
			'small': 1500
			'medium': 2000
			'large': 5000
			'epic': 10000

		'planet.count':
			'fewer': 10
			'few': 20
			'normal': 30
			'plenty': 50


	setupPage: () ->
		li = (container) ->
			$('<li></li>').appendTo(container)

		# Add selection boxes.
		@selectionBoxes = []
		@selectionBoxes.push new SelectionBox(li('#mapPrefs ul'),
			'mapSize', Object.keys(@presets['mapSize']), 2)
		@selectionBoxes.push new SelectionBox(li('#mapPrefs ul'),
			'planet.count', Object.keys(@presets['planet.count']), 2)

		# Add ranges with tooltips.
		new Range(li('#gamePrefs ul'), 'Duration (min)',
			'duration', 3, 20, 1, 5)

		new Range(li('#bonusPrefs ul'), 'Drop wait (ms)',
			'bonus.waitTime', 1000, 10000, 1000, 5000)
		new Range(li('#bonusPrefs ul'), 'Activation wait (ms)',
			'bonus.states.incoming.countdown', 500, 5000, 500, 2000)
		new Range(li('#bonusPrefs ul'), 'Max allowed',
			'bonus.maxCount', 0, 20, 1, 10)
		new Range(li('#bonusPrefs ul'), 'Mines in bonus',
			'bonus.mine.mineCount', 1, 10, 1, 2)

		new Range(li('#bonusAppearancePrefs ul'), 'Mines weight',
			'bonus.bonusType.mine.weight', 0, 10, 1, 3)
		new Range(li('#bonusAppearancePrefs ul'), 'Boost weight',
			'bonus.bonusType.boost.weight', 0, 10, 1, 3)
		new Range(li('#bonusAppearancePrefs ul'), 'Shield weight',
			'bonus.bonusType.shield.weight', 0, 10, 1, 3)
		new Range(li('#bonusAppearancePrefs ul'), 'Stealth weight',
			'bonus.bonusType.stealth.weight', 0, 10, 1, 3)
		new Range(li('#bonusAppearancePrefs ul'), 'Tracker weight',
			'bonus.bonusType.tracker.weight', 0, 10, 1, 3)

		new Range(li('#shipPrefs ul'), 'Speed',
			'ship.speed', 0.1, 1, 0.1, 0.3)
		new Range(li('#shipPrefs ul'), 'Friction Decay',
			'ship.frictionDecay', 0, 1, 0.01, 0.97)

		new Range(li('#botPrefs ul'), 'Count',
			'bot.count', 0, 10, 1, 1)

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
				id: data.id
				prefs: data
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

		for sb in @selectionBoxes
			insert(prefs, sb.name, @presets[sb.name][sb.value()])

		return prefs

# Entry point.
$(document).ready () ->
	window.index = new Index()
