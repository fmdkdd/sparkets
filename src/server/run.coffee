Server = require('./server').Server

# Launch the server.
server = new Server()
server.start () ->
  server.createGame()
