var port = 12345;

var http = require('http');
var io = require('socket.io');
var url = require('url');
var fs = require('fs');

//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
// HTTP server setup

server = http.createServer(function(req, res) {
	var path = url.parse(req.url).pathname;
	switch (path) {
		// Allow only these three files.
	case '/client.html':
	case '/client.js':
	case '/jquery-1.5.2.min.js':
		fs.readFile(__dirname + path, function(err, data){
			if (err) return send404(res);
			res.writeHead(200, {'Content-Type': js(path) ?
			                    'text/javascript' :
			                    'text/html'});
			res.write(data, 'utf8');
			res.end();
		});
		break;

	default: send404(res);
	}
});

function send404(res) {
	res.writeHead(404, {'Content-Type':'text/html'});
	res.end('<h1>Nothing to see here, move along</h1>');
}

server.listen(port);

//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
// Socket.IO setup

var io = io.listen(server);

io.on('clientConnect', onConnect);
io.on('clientMessage', onMessage);
io.on('clientDisconnect', onDisconnect);

console.log("Server started");

//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
// Game server handling

var players = {};
var planets = initPlanets();

function onConnect(player) {
	// Send list of connected players.
	for (var p in players)
		player.send({ type: 'player joins',
		              playerId: players[p] });

	// Add new player to player list.
	var id = player.sessionId;
	players[id] = id;

	// Good news!
	player.send({ type: 'connected',
	              playerId: id });

	// Send the playfield.
	planets.forEach(function(p) {
		player.send({ type: 'planet',
		              planet: p });
	});

	// Poke all other players.
	player.broadcast({ type: 'player joins',
	                   playerId: id });
}

function onMessage(obj, player) {
	// Broadcast message.
	player.broadcast(obj);
}

function onDisconnect(player) {
	// Tell everyone.
	player.broadcast({ type: 'player quits',
	                   playerId: player.sessionId });
}

function initPlanets() {
	var planets = [];
	for (var i=0; i < 4; ++i) {
		planets.push({ x: Math.random()*800,
		               y: Math.random()*600,
		               size: 50+Math.random()*50 });
	}
	return planets;
}

//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
// Utilities
function log(msg) { console.log(msg); };
function error(msg) { console.error(msg); };
function js(path) { return path.match(/js$/) };