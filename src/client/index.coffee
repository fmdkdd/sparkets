$(document).ready () ->

	# Server.
	window.socket = null

	# Connect to server and set callbacks.
	window.socket = io.connect()

	# Grab the game list every minute.
	setInterval( (() =>
		window.socket.emit('get game list')), 60 * 1000)

	# Fetch the game list at first connection.
	window.socket.on 'connect', () =>
		window.socket.emit 'get game list'

	# Update list of running games.
	window.socket.on 'game list', (data) =>
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

	# Expand SPARKETS' name.
	$('header h1').hover (event) ->

		# It's a one time thing!
		$(this).unbind('hover')

		fragments = []
		fragments.push $(e) for e in $('*', $(this))

		leftPos = fragments[0].position().left
		for i in [1...fragments.length]

			f = fragments[i]
			id = f.attr('id')
			num = id.substr(id.length-1)

			leftPos += fragments[i-1].width()

			f.animate({
				left: if f.css('position') is 'absolute' then leftPos+'px' else (leftPos-f.position().left)+'px'
				opacity: if num is '2' or num is '4' then 0.3 else 1
			},	500)

	# Setup log in and sign up forms.
	$('#login, #signup').click (event) =>
		return if window.accountForm?

		# Popup the forms.
		new AccountForm()

		# Focus on the appropriate field.
		if event.target.id is 'login'
			window.accountForm.formLogin.find('input[name="username"]').focus()
		else
			window.accountForm.formSignup.find('input[name="username"]').focus()
