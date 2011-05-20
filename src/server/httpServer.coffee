http = require 'http'
url = require 'url'
fs = require 'fs'

mime = (path) ->
	return 'text/javascript' if path.match(/js$/)
	return 'text/html' if path.match(/html$/)
	return 'text/css' if path.match(/css$/)
	return 'image/png' if path.match(/png$/)

server = http.createServer (req, res) ->
	path = url.parse(req.url).pathname
	switch path
		when '/client.html', '/client.css', '/client.js', '/colorWheel.png', '/colorCursor.png', '/closeButton.png'
			fs.readFile __dirname + '/../..' + path, (err, data) ->
				return send404(res) if err?
				res.writeHead 200,
					'Content-Type': mime path
				res.write data, 'utf8'
				res.end()
		else send404(res)

send404 = (res) ->
	res.writeHead 404, 'Content-Type': 'text/html'
	res.end '<h1>Nothing to see here, move along</h1>'

exports.server = server

