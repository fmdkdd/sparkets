logger = require './logger'
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

# Setup global server callbacks
globalSockets = io.of('')

globalSockets.on 'connection', (socket) ->
	logger.info "Player #{socket.id} joined global server"

	socket.on 'disconnect', () ->
		logger.info "Player #{socket.id} left global server"

	socket.on 'get game list', () ->
		socket.emit 'game list',
			list: Object.keys(gameList)

logger.info 'Global server started'

GameServer = require('./gameServer').GameServer
gameList = {}
createGame = (id) ->
	game = new GameServer(io.of(id))
	game.launch()
	logger.info "Game #{id} started"
	return gameList[id] = game

# Default game for all users
createGame('#test')

# Start the admin REPL and expose game server object.
repl = require 'webrepl'
replServ = repl.start(prefs.server.replPort)
replServ.context.createGame = createGame
replServ.context.stop = () ->
	httpServer.close()
	process.exit()
