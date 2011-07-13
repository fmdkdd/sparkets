vows = require('vows')
assert = require('assert')

# Setup
http = require('http')
server = require('../../build/server/httpServer').create()

port = 15000

# Tests

exports.suite = vows.describe('HTTP server')

exports.suite.addBatch
	'Listen':
		topic: () ->
			server.listen(port, @callback)
			return

		'GET /':
			topic: () ->
				http.get
					host: 'localhost'
					port: port
					path: '/', @callback
				return

			'should respond OK (200)': (res, err) ->
				assert.equal(res.statusCode, 200)

			'should serve HTML': (res, err) ->
				assert.equal(res.headers['content-type'], 'text/html')

		'GET /img/colorWheel.png':
			topic: () ->
				http.get
					host: 'localhost'
					port: port
					path: '/img/colorWheel.png', @callback
				return

			'should respond OK (200)': (res, err) ->
				assert.equal(res.statusCode, 200)

			'should server PNG': (res, err) ->
				assert.equal(res.headers['content-type'], 'image/png')

		'teardown': () ->
			server.close()
