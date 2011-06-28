prefs = require './prefs'

# Start webserver
httpServer = require('./httpServer').server

httpServer.listen prefs.server.port

# Bind websocket
io = require 'socket.io'

io = io.listen httpServer
io.configure () ->
	io.set('transports', ['websocket', 'flashsocket'])
	io.set('log level', 2)

# Launch game server
GameServer = require('./gameServer').GameServer

exports.game = new GameServer(io)
exports.game.launch()
console.info 'Server started'

# Start the admin REPL and expose game server object.
repl = require 'webrepl'
replServ = repl.start(prefs.server.replPort)
replServ.context.game = exports.game
replServ.context.stop = () ->
	httpServer.close()
	process.exit()
