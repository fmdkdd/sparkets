$(document).ready () ->

	# Setup tabbed panels.	
	$('#form li a').click (event) ->

		# Do not follow the clicked link.
		event.preventDefault()

		oldTab = $('#form li a.selected')
		if oldTab.length > 0	

			# Unselect the current tab.
			oldTab.removeClass('selected')

			# Hide the current panel.
			$('#panel' + oldTab.attr('id').substr(@.id.length-1, 1)).hide()

		# Select the new tab
		$(@).addClass('selected')

		# Display the new panel.
		$('#panel' + @.id.substr(@.id.length-1, 1)).show()

	# 
	window.presets =
		mapSize:
			'tiny': 1000
			'small': 1500
			'medium': 2000
			'large': 5000
			'epic': 10000

		'planet.density':
			'few': .15
			'normal': .35
			'plenty': .5
			'excessive': .7

	# Fill the form.

	entry = (container, label) ->
		tr = (container) ->
			$('<tr class="entry"></tr>').appendTo(container)

		c = $('<td>' + label + '</td>').appendTo(tr(container))
		$('<td></td>').insertAfter(c)

	new Range(entry('#panel1 table', 'Game duration (min)'),
		'duration', 3, 20, 1, 5)

	window.selectionBoxes = []
	window.selectionBoxes.push new SelectionBox(entry('#panel2 > table', 'Map size'),
		'mapSize', Object.keys(window.presets['mapSize']), 2)
	window.selectionBoxes.push new SelectionBox(entry('#panel2 > table', 'Planet density'),
		'planet.density', Object.keys(window.presets['planet.density']), 1)

	new Range(entry('#panel3 > table', 'Drop wait (ms)'),
		'bonus.waitTime', 1000, 10000, 1000, 5000)
	new Range(entry('#panel3 > table', 'Activation wait (ms)'),
		'bonus.states.incoming.countdown', 500, 5000, 500, 2000)
	new Range(entry('#panel3 > table', 'Max allowed'),
		'bonus.maxCount', 0, 20, 1, 10)
	new Range(entry('#panel3 > table', 'Mines in bonus'),
		'bonus.mine.mineCount', 1, 10, 1, 2)
	new Range(entry('#panel3 > table', 'Mines weight'),
		'bonus.bonusType.mine.weight', 0, 10, 1, 3)
	new Range(entry('#panel3 > table', 'Boost weight'),
		'bonus.bonusType.boost.weight', 0, 10, 1, 3)
	new Range(entry('#panel3 >  table', 'Shield weight'),
		'bonus.bonusType.shield.weight', 0, 10, 1, 3)
	new Range(entry('#panel3 > table', 'Stealth weight'),
		'bonus.bonusType.stealth.weight', 0, 10, 1, 3)
	new Range(entry('#panel3 > table', 'Tracker weight'),
		'bonus.bonusType.tracker.weight', 0, 10, 1, 3)
	new Range(entry('#panel3 > table', 'EMP weight'),
		'bonus.bonusType.EMP.weight', 0, 10, 1, 3)

	new Range(entry('#panel4 > table', 'Speed'),
		'ship.speed', 0.1, 1, 0.1, 0.3)
	new Range(entry('#panel4 > table', 'Friction decay'),
		'ship.frictionDecay', 0, 1, 0.01, 0.97)
	new Range(entry('#panel4 > table', 'Bot count'),
		'bot.count', 0, 10, 1, 1)

	# Connect to server and setup callbacks.
	window.socket = io.connect()

	window.socket.on 'connect', () ->
		# Do something?

	window.socket.on 'game already exists', () ->
		$('#error').html('Name already exists')

	window.socket.on 'game created', (data) ->
		# Redirect to the client page.
		window.location.replace('../play/#' + data.id)

	window.socket.on 'game list', (data) ->
		idList = Object.keys(data)
		if idList.length > 0
			gameListRegexp = new RegExp('^(' + idList.join('|') + ')$')
		else
			gameListRegexp = null

	# Setup form handling.
	$('input[name="id"]').keyup (event) ->
		if gameListRegexp? and event.target.value.match(gameListRegexp)
			$('#error').html('Name already exists')
			$('input[value="Create"]').attr('disabled', 'disabled')
		else
			$('#error').html('')
			$('input[value="Create"]').removeAttr('disabled')

	$('input[type="submit"]').click (event) ->
		event.preventDefault()
		data = gatherValues()

		# Prepare game options.
		opts =
			id: data.id
			prefs: data
		delete data.id

		window.socket.emit 'create game', opts, () ->
			# Clear and unfocus game name input on creation.
			nameInput = $('#panel1 input[name="id"]')
			nameInput.val('')
			nameInput.blur()

	gatherValues = () ->
		insert = (obj, name, val) ->
			[prop, rest...] = name.split('.')

			if rest.length > 0
				obj[prop] = {} if not obj[prop]?
				insert(obj[prop], rest.join('.'), val)
			else
				obj[name] = val

		prefs = {}
		for input in $('#form').find('input')
			if input.name? and input.value?
				switch input.type
					when 'text'
						insert(prefs, input.name, input.value)
					when 'range'
						insert(prefs, input.name, parseFloat(input.value))

		for sb in @selectionBoxes
			insert(prefs, sb.name, window.presets[sb.name][sb.value()])

		return prefs
