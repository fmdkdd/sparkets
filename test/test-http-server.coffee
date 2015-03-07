vows = require('vows')
assert = require('assert')

# Setup
http = require('http')
server = require('../build/server/httpServer').create()

port = 15000

# Tests

exports.suite = vows.describe('HTTP server')

exports.suite.addBatch
  '':
    topic: () ->
      server.listen(port, @callback)
      return

    'GET /':
      topic: () ->
        http.get
          host: 'localhost'
          port: port
          path: '/', (res) => @callback(null, res)
        return

      'should respond OK (200)': (err, res) ->
        assert.isNull(err)
        assert.equal(res.statusCode, 200)

      'should serve HTML': (err, res) ->
        assert.isNull(err)
        assert.equal(res.headers['content-type'], 'text/html')

    'GET /img/colorWheel.png':
      topic: () ->
        http.get
          host: 'localhost'
          port: port
          path: '/img/colorWheel.png', (res) => @callback(null, res)
        return

      'should respond OK (200)': (err, res) ->
        assert.isNull(err)
        assert.equal(res.statusCode, 200)

      'should serve PNG': (err, res) ->
        assert.isNull(err)
        assert.equal(res.headers['content-type'], 'image/png')

    'GET /zorglub':
      topic: () ->
        http.get
          host: 'localhost'
          port: port
          path: '/zorglub', (res) => @callback(null, res)
        return

      'should respond Not Found (404)': (err, res) ->
        assert.isNull(err)
        assert.equal(res.statusCode, 404)

    teardown: () ->
      server.close()
