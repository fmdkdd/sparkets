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
