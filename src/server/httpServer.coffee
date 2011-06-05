http = require 'http'
url = require 'url'
fs = require 'fs'

mime = (path) ->
	return 'text/javascript' if path.match(/js$/)
	return 'text/html' if path.match(/html$/)
	return 'text/css' if path.match(/css$/)
	return 'image/png' if path.match(/png$/)
	return 'image/svg+xml' if path.match(/svg$/)

webFiles = {
	'/' : '/client.html',
	'/client.html',
	'/client.css',
	'/client.js',
	'/favicon.ico',
	'/img/colorWheel.png',
	'/img/colorCursor.png',
	'/img/closeButton.svg',
	'/img/tutorialMove.svg',
	'/img/tutorialShoot.svg',
	'/img/tutorialBonus.svg'
}

server = http.createServer (req, res) ->
	path = url.parse(req.url).pathname
	if webFiles[path]?
		# Server.js file is in build/server and all web files
		# are in www/
		fs.readFile __dirname + '/../../www' + webFiles[path], (err, data) ->
			return send404(res) if err?
			res.writeHead 200, 'Content-Type': mime(path)
			res.write data, 'utf8'
			res.end()
	else send404(res)

send404 = (res) ->
	res.writeHead 404, 'Content-Type': 'text/html'
	res.end '<h1>Nothing to see here, move along</h1>'

exports.server = server

