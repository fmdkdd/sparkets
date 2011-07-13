server = require('./server')

# Launch the server.
server.start {}, () ->
	# Default game for all users
	server.createGame('test')
