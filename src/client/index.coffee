class Index
	constructor: () ->

		# Server.
		@socket = null

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

# Entry point.
$(document).ready () ->
	window.index = new Index()
