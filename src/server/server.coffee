logger = require '../logger'
ServerPreferences = require('./prefs').ServerPreferences

io = require 'socket.io'
httpServer = require('./httpServer')

gameList = exports.gameList = {}
sendGameList = (socket) ->
	msg = {}

	for id, game of gameList
		msg[id] =
			players: game.humanCount() + game.botCount()
			startTime: game.startTime
			duration: game.prefs.duration

	socket.emit('game list', msg)

GameServer = require('./gameServer').GameServer
createGame = exports.createGame = (id, gamePrefs) ->
	endGame = () ->
		game.end()
		delete gameList[id]

		sendGameList(globalSockets)

	game = new GameServer(io.of(id), gamePrefs)
	game.launch()

	# Prepare game expiration.
	setTimeout(endGame, game.prefs.duration * 60 * 1000)

	logger.info "Game #{id} started"

	return gameList[id] = game

exports.start = (prefs, callback) ->
	# Init preferences
	prefs = new ServerPreferences(prefs)

	# Start the admin REPL and expose game server object.
	repl = require 'webrepl'
	replServ = repl.start(prefs.replPort)
	replServ.context.createGame = createGame
	replServ.context.stop = () ->
		exports.close()
		process.exit()

	httpServer = httpServer.create()

	# Bind websocket
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
			sendGameList(socket)

		socket.on 'create game', (data) ->
			gameId = data.id
			delete data.id

			# Game with ID already exists, don't create.
			if gameList[gameId]?
				socket.emit 'game already exists'

			else
				createGame(gameId, data)

				sendGameList(globalSockets)

	httpServer.listen prefs.port, () ->
		logger.info "Global server started on port #{prefs.port}"

		callback()

exports.stop = () ->
	httpServer.close()
