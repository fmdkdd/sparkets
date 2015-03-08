logger = require('../logger')
ServerPreferences = require('./prefs').ServerPreferences
GameServer = require('./gameServer').GameServer

WebSocketServer = require('ws').Server
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
    @wsServer = new WebSocketServer {port: @prefs.webSocketPort}
    @wsServer.broadcast = (data) =>
      client.send data for client in @wsServer.clients

    # Start listening!
    @httpServer.listen @prefs.httpPort, () =>
      @logger.info "Global server started on port #{@prefs.httpPort}"
      @logger.info "Browse to http://localhost:#{@prefs.httpPort} to play!"

      callback()

  stop: () ->
    @httpServer.close()

  createGame: (gamePrefs) ->
    game = new GameServer(@wsServer, gamePrefs)
    game.launch()

    return game

  startRepl: () ->
    # Start the admin REPL and expose some utilities.
    @replServ = repl.start(@prefs.replPort)
    @replServ.context.createGame = @createGame
    @replServ.context.message = require('../message')
    @replServ.context.stop = () =>
      @stop()

      # WebREPL creates a HTTP server but does not allow us to
      # close it.
      process.exit()

exports.Server = Server
