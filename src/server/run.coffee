Server = require('./server').Server

# Launch the server.
server = new Server()
server.start () ->
  # Default game for all users
  server.createGame('test')
