vows = require('vows')
assert = require('assert')

test = vows.describe('HTTP server').addBatch
	'GET /':
		topic: () ->
			require('http').get
				host: 'localhost'
				port: 12345
				path: '/', @callback
			return

		'should respond OK (200)': (res, err) ->
			assert.equal(res.statusCode, 200)

		'should serve HTML': (res, err) ->
			assert.equal(res.headers['content-type'], 'text/html')

	'GET /img/colorWheel.png':
		topic: () ->
			require('http').get
				host: 'localhost'
				port: 12345
				path: '/img/colorWheel.png', @callback
			return

		'should respond OK (200)': (res, err) ->
			assert.equal(res.statusCode, 200)

		'should server PNG': (res, err) ->
			assert.equal(res.headers['content-type'], 'image/png')

test.run()
