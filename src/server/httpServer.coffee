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
	'/' : '/index.html',
	'/play/' : '/client.html',
	'/client.css',
	'/index.css',
	'/js/client/bonus.js',
	'/js/client/boostEffect.js',
	'/js/client/bullet.js',
	'/js/client/client.js',
	'/js/client/EMP.js',
	'/js/client/explosionEffect.js',
	'/js/client/index.js',
	'/js/client/menu.js',
	'/js/client/mine.js',
	'/js/client/dislocateEffect.js',
	'/js/client/planet.js',
	'/js/client/rope.js',
	'/js/client/ship.js',
	'/js/client/tracker.js',
	'/js/utils.js',
	'/favicon.ico',
	'/img/colorWheel.png',
	'/img/colorCursor.png',
	'/img/iconClose.svg',
	'/img/iconDeath.svg',
	'/img/iconKill.svg',
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
