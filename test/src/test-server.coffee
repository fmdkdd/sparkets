vows = require('vows')
assert = require('assert')

# Setup
http = require('http')
require('../common')

server = require('../../build/server/server')
port = 15100
replPort = 15150

# Suppress socket.io console output.
console.log = () ->

# Tests

exports.suite = vows.describe('Server')

exports.suite.addBatch
	'start server':
		topic: () ->
			server.start
				port: port
				replPort: replPort
				log: []
				io: {logLevel: 3}, @callback
			return

		'create game':
			topic: () ->
				server.createGame('a', {timestep: 123})

			'should add to game list': (game) ->
				assert.include(server.gameList, 'a')

			'should launch game': (game) ->
				assert.isNumber(game.startTime)

			'should honor prefs': (game) ->
				assert.equal(123, game.prefs.timestep)

		'should start HTTP server':
			topic: () ->
				http.get
					host: 'localhost'
					port: port
					path: '/', @callback
				return

			'respond OK': (res, err) ->
				assert.equal(res.statusCode, 200)

		'should start REPL':
			topic: () ->
				http.get
					host: 'localhost'
					port: replPort
					path: '/', @callback
				return

			'respond with OK': (res, err) ->
				assert.equal(res.statusCode, 200)

		# Test socket events.
		'on `create game` event':
			topic: () ->
				cl = client(port)
				cl.handshake (sid) =>
					ws = websocket(cl, sid)
					ws.on 'open', () ->
						ws.event 'create game',
							id: 'bar'

					ws.on 'message', (packet) =>
						if packet.type is 'event'
							@callback(packet)
				return

			'should return game list': (packet, err) ->
				assert.equal(packet.name, 'game list')

			'should create requested game': (packet, err) ->
				assert.include(packet.args[0], 'bar')

		'on `get game list` event':
			topic: () ->
				cl = client(port)
				cl.handshake (sid) =>
					ws = websocket(cl, sid)
					ws.on 'open', () ->
						ws.event 'get game list'

					ws.on 'message', (packet) =>
						if packet.type is 'event'
							@callback(packet)
				return

			'should return game list': (packet, err) ->
				assert.equal(packet.name, 'game list')

	'teardown': () ->
		server.stop()
