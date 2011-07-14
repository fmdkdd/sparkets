logger = require('../logger')
ServerPreferences = require('./prefs').ServerPreferences

GameServer = require('./gameServer').GameServer
io = require('socket.io')
httpServer = require('./httpServer')
repl = require('webrepl')

class Server
	constructor: (@prefs) ->
		@gameList = {}

	start: (callback) ->
		# Init preferences
		@prefs = new ServerPreferences(@prefs)

		# Toggle log levels from prefs.
		@logger = logger.set(@prefs.log)

		@startRepl()

		@httpServer = httpServer.create()

		# Bind websocket
		@io = io.listen(@httpServer)
		@io.configure () =>
			# XXX: Log level can be set only when called first.
			@io.set('log level', @prefs.io.logLevel)
			@io.set('transports', @prefs.io.transports)

		# Bind global namespace.
		@globalSockets = @io.of('')
		@setupCallbacks()

		# Start listening!
		@httpServer.listen @prefs.port, () =>
			@logger.info "Global server started on port #{@prefs.port}"

			callback()

	stop: () ->
		@httpServer.close()

	setupCallbacks: () ->
		@globalSockets.on 'connection', (socket) =>
			@logger.info "Player #{socket.id} joined global server"

			socket.on 'disconnect', () =>
				@logger.info "Player #{socket.id} left global server"

			socket.on 'get game list', () =>
				@logger.info "game list requested"
				@sendGameList(socket)

			socket.on 'create game', (data) =>
				@logger.info "game creation requested"
				if @gameList[data.id]?
					socket.emit 'game already exists'
				else
					@createGame(data.id, data.prefs)

	createGame: (id, gamePrefs) ->
		# Game with ID already exists, don't create.
		return @gameList[id] if @gameList[id]?

		@gameList[id] = game = new GameServer(@io.of(id), gamePrefs)
		game.launch()

		@logger.info "Game #{id} started"

		# Prepare game expiration.
		setTimeout( (() =>
			@endGame(id)), game.prefs.duration * 60 * 1000)

		@sendGameList(@globalSockets)

		return game

	endGame: (id) ->
		if @gameList[id]?
			@gameList[id].end()
			delete @gameList[id]

			@sendGameList(@globalSockets)

	sendGameList: (socket) ->
		msg = {}

		for id, game of @gameList
			msg[id] =
				players: game.humanCount() + game.botCount()
				startTime: game.startTime
				duration: game.prefs.duration

		socket.emit('game list', msg)

	startRepl: () ->
		# Start the admin REPL and expose some utilities.
		@replServ = repl.start(@prefs.replPort)
		@replServ.context.createGame = @createGame
		@replServ.context.gameList = @gameList
		@replServ.context.stop = () =>
			@stop()

			# WebREPL creates a HTTP server but does not allow us to
			# close it.
			process.exit()

exports.Server = Server
