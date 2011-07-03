window.socket = {}

window.socket = io.connect()
window.socket.on 'connect', () ->
	window.socket.emit 'get game list'

window.socket.on 'game list', (data) ->
	for id in data.list
		href = '/play/' + id
		$('#gameList').append('<li><a href="' + href + '">' + id + '</a></li>')
