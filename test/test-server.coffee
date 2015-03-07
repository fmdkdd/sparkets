vows = require('vows')
assert = require('assert')

# Setup
http = require('http')
require('./support/common')
Server = require('../build/server/server').Server

port = 15100
replPort = 15150

createServer = (port, replPort) ->
  serv = new Server
    port: port
    replPort: replPort
    log: []
    io:
      transports: ['websocket']
      logLevel: -1

  # Suppress socket.io console output.
  console.log = () ->

  return serv

openSocket = (port, callback) ->
  cl = client(port)
  cl.handshake (sid) ->
    ws = websocket(cl, sid)
    ws.on 'open', () ->
      callback(ws)

# Tests

exports.suite = vows.describe('Server')

exports.suite.addBatch
  '':
    topic: () ->
      @server = createServer(port, replPort)
      @server.start(@callback)
      return

    'create game':
      topic: () ->
        @server.createGame('a', {mapSize: 123})

      'should add to game list': (game) ->
        assert.include(@server.gameList, 'a')

      'should launch game': (game) ->
        assert.isNumber(game.startTime)

      'should honor prefs': (game) ->
        assert.equal(123, game.prefs.mapSize)

      'delete game':
        topic: () ->
          @server.endGame('a')

        'should remove game from game list': () ->
          assert.isFalse('a' of @server.gameList)

    'create another game':
      topic: () ->
        @server.createGame('b', {mapSize: 123})

      'should add to game list': (game) ->
        assert.include(@server.gameList, 'b')

      'should launch game': (game) ->
        assert.isNumber(game.startTime)

      'should honor prefs': (game) ->
        assert.equal(123, game.prefs.mapSize)

      'create another game with the same name':
        topic: () ->
          @server.createGame('b', {mapSize: 10})

        'should preserve existing game': (game) ->
          assert.equal(123, game.prefs.mapSize)

    'should start HTTP server':
      topic: () ->
        http.get
          host: 'localhost'
          port: port
          path: '/', (res) => @callback(null, res)
        return

      'respond OK': (err, res) ->
        assert.isNull(err)
        assert.equal(res.statusCode, 200)

    'should start REPL':
      topic: () ->
        http.get
          host: 'localhost'
          port: replPort
          path: '/', (res) => @callback(null, res)
        return

      'respond with OK': (err, res) ->
        assert.isNull(err)
        assert.equal(res.statusCode, 200)

    # Test game id validation.
    'create game with empty name': () ->
      assert.throws (() =>
        @server.createGame('')), /invalid game id/

    'create game with bogus name': () ->
      test = (str) =>
        assert.throws (() =>
          @server.createGame(str)), /invalid game id/

      test('//')
      test('/')
      test('«foo»')
      test('#')
      test('#a')
      test('!')
      test('!a')
      test('.')
      test('*')
      test('   ')
      test('ßáíðþ¡ºª’~//œæçó»«’‘€¢–.*#')

    'create game with valid name': () ->
      test = (str) =>
        assert.doesNotThrow (() =>
          @server.createGame(str)), /invalid game id/

      test('foo')
      test('Foo')
      test('F00')
      test('123')

    teardown: () ->
      @server.stop()

# exports.suite.addBatch
#   '':
#     topic: () ->
#       @server = createServer(port, replPort)
#       @server.start(@callback)
#       return

#     'on `create game` event':
#       topic: () ->
#         openSocket port, (ws) =>
#           ok = waiter(@callback)
#           ws.on 'message', (packet) ->
#             ok(packet) if packet.type is 'event'

#           ws.event 'create game',
#             id: 'bar'
#         return

#       'should broadcast the game list': (err, packet) ->
#         assert.isNull(err)
#         if packet.name is 'game list'
#           assert.ok(packet.name)

#       'should return `game created` event': (err, packet) ->
#         assert.isNull(err)
#         if packet.name is 'game created'
#           assert.ok(packet.name)

#       'should create requested game': (err, packet) ->
#         assert.isNull(err)
#         if packet.name is 'game list'
#           assert.include(packet.args[0], 'bar')
#         if packet.name is 'game created'
#           assert.deepEqual(packet.args[0], {id: 'bar'})

#     teardown: () ->
#       @server.stop()

# exports.suite.addBatch
#   '':
#     topic: () ->
#       @server = createServer(port, replPort)
#       @server.start(@callback)
#       return

#     'on `get game list` event':
#       topic: () ->
#         openSocket port, (ws) =>
#           ok = waiter(@callback)
#           ws.on 'message', (packet) ->
#             ok(packet) if packet.type is 'event'

#           ws.event 'get game list'
#         return

#       'should return the game list': (err, packet) ->
#         assert.isNull(err)
#         assert.strictEqual(packet.name, 'game list')

#     teardown: () ->
#       @server.stop()

# exports.suite.addBatch
#   '':
#     topic: () ->
#       @server = createServer(port, replPort)
#       @server.start(@callback)
#       return

#     'created game':
#       topic: () ->
#         openSocket port, (ws) =>
#           ok = waiter(@callback)
#           msg = 0
#           ws.on 'message', (packet) =>
#             if packet.type is 'event' and packet.name is 'game list'
#               ++msg
#               ok(packet) if msg is 2

#           ws.event 'create game',
#             id: 'bar'
#             prefs: {duration: 0}
#         return

#       'should send the game list twice': (err, packet) ->
#         assert.isNull(err)
#         assert.isTrue(packet?)

#       'should expire': (err, packet) ->
#         assert.isNull(err)
#         assert.isTrue(packet?)
#         assert.isEmpty(packet.args[0])

#     teardown: () ->
#       @server.stop()
