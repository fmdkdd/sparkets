logger = require './logger'
ServerPreferences = require('./prefs').ServerPreferences

# Init preferences
prefs = new ServerPreferences()

# Start webserver
httpServer = require('./httpServer').server

httpServer.listen prefs.port

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

	socket.on 'create game', (data) ->
		gameId = data.id
		delete data.id

		# Game with ID already exists, don't create.
		if gameList[gameId]?
			socket.emit 'game already exists'

		else
			createGame(gameId, data)

			globalSockets.emit 'game list'
				list: Object.keys(gameList)

logger.info 'Global server started'

GameServer = require('./gameServer').GameServer
gameList = {}
createGame = (id, gamePrefs) ->
	endGame = () ->
		game.end()
		delete gameList[id]

		globalSockets.emit 'game list'
			list: Object.keys(gameList)

	game = new GameServer(io.of(id), gamePrefs)
	game.launch()

	# Prepare game expiration.
	setTimeout(endGame, game.prefs.duration * 1000)

	logger.info "Game #{id} started"

	return gameList[id] = game

# Default game for all users
createGame('test')

# Start the admin REPL and expose game server object.
repl = require 'webrepl'
replServ = repl.start(prefs.replPort)
replServ.context.createGame = createGame
replServ.context.stop = () ->
	httpServer.close()
	process.exit()
