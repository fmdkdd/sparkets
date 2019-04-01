http = require 'http'
url = require 'url'
fs = require 'fs'

mime = (path) ->
  return 'text/javascript' if path.match(/js$/)
  return 'text/html' if path.match(/html$/)
  return 'text/css' if path.match(/css$/) or path.match(/less$/)
  return 'image/png' if path.match(/png$/)
  return 'image/svg+xml' if path.match(/svg$/)
  return 'image/vnd.microsoft.com' if path.match(/ico$/)

webFiles = {
  '/' : '/index.html',
  '/create/' : '/create.html'
  '/create' : '/create.html'
  '/play/' : '/client.html',
  '/bonusBox.less',
  '/client.less',
  '/common.less',
  '/create.less',
  '/index.less',
  '/range.less',
  '/selectionBox.less',
  '/lib/jquery-1.7.2.min.js',
  '/lib/less-1.1.3.min.js',
  '/js/client/bonus.js',
  '/js/client/boostEffect.js',
  '/js/client/bonusBox.js',
  '/js/client/bullet.js',
  '/js/client/chargingEffect.js',
  '/js/client/chat.js',
  '/js/client/client.js',
  '/js/client/create.js',
  '/js/client/dislocateEffect.js',
  '/js/client/EMP.js',
  '/js/client/explosionEffect.js',
  '/js/client/flashEffect.js',
  '/js/client/grenade.js',
  '/js/client/boxed.js',
  '/js/client/index.js',
  '/js/client/menu.js',
  '/js/client/mine.js',
  '/js/client/planet.js',
  '/js/client/range.js',
  '/js/client/rope.js',
  '/js/client/selectionBox.js',
  '/js/client/shield.js',
  '/js/client/ship.js',
  '/js/client/spriteManager.js',
  '/js/client/tooltip.js',
  '/js/client/tracker.js',
  '/js/client/trailEffect.js',
  '/js/utils.js',
  '/js/message.js',
  '/favicon.ico',
  '/img/colorWheel.png',
  '/img/colorCursor.png',
  '/img/iconBot.svg',
  '/img/iconClose.svg',
  '/img/iconDeath.svg',
  '/img/iconKill.svg',
  '/img/iconTalk.svg',
  '/img/triangle.svg',
  '/img/tutorialMove.svg',
  '/img/tutorialShoot.svg',
  '/img/tutorialBonus.svg'
}

send404 = (res) ->
  res.writeHead 404, 'Content-Type': 'text/html'
  res.end '<h1>Nothing to see here, move along</h1>'

handleRequest = (req, res) ->
  path = url.parse(req.url).pathname
  if webFiles[path]?
    # Server.js file is in build/server and all web files
    # are in www/
    fs.readFile __dirname + '/../../www' + webFiles[path], (err, data) ->
      return send404(res) if err?
      res.writeHead 200, 'Content-Type': mime(webFiles[path])
      res.write data, 'utf8'
      res.end()
  else send404(res)

exports.create = () ->
  http.createServer(handleRequest)
