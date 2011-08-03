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
