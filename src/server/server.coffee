prefs = require './prefs'

# Start webserver
httpServer = require('./httpServer').server

httpServer.listen prefs.server.port

# Bind websocket
socket = require 'socket.io'

socket = socket.listen httpServer

# Launch game server
GameServer = require('./gameServer').GameServer

exports.game = new GameServer(socket)
exports.game.launch()
console.info 'Server started'

