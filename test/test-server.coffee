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
		io: {logLevel: -1}

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
				@server.createGame('a', {timestep: 123})

			'should add to game list': (game) ->
				assert.include(@server.gameList, 'a')

			'should launch game': (game) ->
				assert.isNumber(game.startTime)

			'should honor prefs': (game) ->
				assert.equal(123, game.prefs.timestep)

			'delete game':
				topic: () ->
					@server.endGame('a')

				'should remove game from game list': () ->
					assert.isFalse('a' of @server.gameList)

		'create another game':
			topic: () ->
				@server.createGame('b', {timestep: 123})

			'should add to game list': (game) ->
				assert.include(@server.gameList, 'b')

			'should launch game': (game) ->
				assert.isNumber(game.startTime)

			'should honor prefs': (game) ->
				assert.equal(123, game.prefs.timestep)

			'create another game with the same name':
				topic: () ->
					@server.createGame('b', {timestep: 10})

				'should preserve existing game': (game) ->
					assert.equal(123, game.prefs.timestep)

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

exports.suite.addBatch
	'':
		topic: () ->
			@server = createServer(port, replPort)
			@server.start(@callback)
			return

		'on `create game` event':
			topic: () ->
				openSocket port, (ws) =>
					ws.event 'create game',
						id: 'bar'

					ok = waiter(@callback)
					ws.on 'message', (packet) ->
						ok(packet) if packet.type is 'event'
				return

			'should return the game list': (err, packet) ->
				assert.isNull(err)
				assert.strictEqual(packet.name, 'game list')

			'should create requested game': (err, packet) ->
				assert.isNull(err)
				assert.include(packet.args[0], 'bar')

		teardown: () ->
			@server.stop()

exports.suite.addBatch
	'':
		topic: () ->
			@server = createServer(port, replPort)
			@server.start(@callback)
			return

		'on `get game list` event':
			topic: () ->
				openSocket port, (ws) =>
					ws.event 'get game list'

					ok = waiter(@callback)
					ws.on 'message', (packet) ->
						ok(packet) if packet.type is 'event'
				return

			'should return the game list': (err, packet) ->
				assert.isNull(err)
				assert.strictEqual(packet.name, 'game list')

		teardown: () ->
			@server.stop()

exports.suite.addBatch
	'':
		topic: () ->
			@server = createServer(port, replPort)
			@server.start(@callback)
			return

		'created game':
			topic: () ->
				openSocket port, (ws) =>
					ws.event 'create game',
						id: 'bar'
						prefs: {duration: 0}

					ok = waiter(@callback)
					msg = 0
					ws.on 'message', (packet) =>
						if packet.type is 'event' and packet.name is 'game list'
							++msg
							ok(packet) if msg is 2
				return

			'should send the game list twice': (err, packet) ->
				assert.isNull(err)
				assert.isTrue(packet?)

			'should expire': (err, packet) ->
				assert.isNull(err)
				assert.isTrue(packet?)
				assert.isEmpty(packet.args[0])

		teardown: () ->
			@server.stop()
