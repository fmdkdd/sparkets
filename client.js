// Server
const port = 12345;
var socket;

const interp_factor = .03;
var lastUpdate = 0;

// Graphics
var ctxt;
var screen = {w : 0, h : 0};
var map = {w : 2000, h : 2000};
var view = {x : 0, y : 0};

const shipColor = '127, 185, 157';
const enemyColor = '187, 127, 135';
const planetColor = '127, 157, 185';

// Game logic
const maxPower = 3;
const maxExploFrame = 50;

var id;
var ships = {};
var serverShips = {};
var planets = [];
var bullets = [];

function init() {
	// Connect to server and set callbacks.
	socket = new io.Socket(null, {port:port});
	socket.connect();
	socket.on('message', onMessage);
	socket.on('connect', onConnect);
	socket.on('disconnect', onDisconnect);

	// Setup canvas
	ctxt = document.getElementById('canvas').getContext('2d');

	$(window).resize(function(event) {
		screen.w = document.getElementById('canvas').width = window.innerWidth;
		screen.h = document.getElementById('canvas').height = window.innerHeight;
		centerView();
	});
	$(window).resize();
}

// Setup input callbacks and launch game loop.
function ready() {
	document.onkeydown = function(event) {
		socket.send({ type: 'key down',
		              playerId: id,
		              key: event.keyCode })};
	document.onkeyup = function(event) {
		socket.send({ type: 'key up',
		              playerId: id,
		              key: event.keyCode })};
	update();
}

function interpolate(time) {
	if (time * interp_factor > 1)
		info(time);

	for (var s in serverShips) {
		var ship = ships[s];
		var shadow = serverShips[s];

		if (typeof ship === 'undefined') {
			ships[s] = shadow;
			continue;
		}

		// X interpolation
		var dx = shadow.pos.x - ship.pos.x;
		if (Math.abs(dx) < .1 || Math.abs(dx) > 100)
			ship.pos.x = shadow.pos.x;
		else
			ship.pos.x += dx * time * interp_factor;

		// Y interpolation
		var dy = shadow.pos.y - ship.pos.y;
		if (Math.abs(dy) < .1  || Math.abs(dy) > 100)
			ship.pos.y = shadow.pos.y;
		else
			ship.pos.y += dy * time * interp_factor;

		// Dir interpolation
		var ddir = shadow.dir - ship.dir;
		if (Math.abs(ddir) < .01)
			ship.dir = shadow.dir;
		else
			ship.dir += ddir * time * interp_factor;

		// Everything else
		ship.vel = shadow.vel;
		ship.dir = shadow.dir;
		ship.color = shadow.color;
		ship.firePower = shadow.firePower;
		ship.dead = shadow.dead;
		ship.exploBits = shadow.exploBits;
		ship.exploFrame = shadow.exploFrame;
	}
}

// Game loop!
function update() {
	var start = (new Date()).getTime();

	interpolate((new Date()).getTime() - lastUpdate);
	centerView();
	redraw(ctxt);

	var diff = (new Date()).getTime() - start;
	setTimeout(update, 20-mod(diff, 20));
}

function inView(x,y) {
	return x >= view.x && x <= view.x + screen.w
		&& y >= view.y && y <= view.y + screen.h;
}

// Clear canvas and draw everything.
// Not efficient, but we don't have that many objects.
function redraw(ctxt) {
	ctxt.clearRect(0, 0, screen.w, screen.h);
	ctxt.lineWidth = 4;
	ctxt.lineJoin = 'round';
	
	// Draw all bullets with decreasing opacity.
	var len = bullets.length;
	for (var b in bullets)
		bullets[b].draw(ctxt, (b+1)/len);

	// Draw all planets.
	for (var p in planets)
		planets[p].draw(ctxt);

	// Draw all ships.
	for (var s in ships)
		ships[s].draw(ctxt);

	if (typeof ships[id] !== 'undefined'
	    && !ships[id].isDead())
		drawRadar(ctxt);

	drawInfinity(ctxt);
}

function centerView() {
	if (typeof ships[id] !== 'undefined') {
		view.x = ships[id].pos.x - screen.w / 2;
		view.y = ships[id].pos.y - screen.h / 2;
	}
}

function drawRadar(ctxt) {
	for (var s in ships) {
		if (s !== id) {
			var dx = ships[s].pos.x - ships[id].pos.x;
			var dy = ships[s].pos.y - ships[id].pos.y;
			var d = Math.sqrt(dx*dx + dy*dy);
			var rx = dx / d * 50;
			var ry = dy / d * 50;

			ctxt.strokeStyle = color(planetColor);
			ctxt.beginPath();
			ctxt.arc(screen.w/2 + rx, screen.h/2 + ry, 2, 0, 2*Math.PI, false);
			ctxt.stroke();
		}
	}
}

function drawInfinity(ctxt) {
	// can the player see the left, right, top and bottom voids?
	var left = view.x < 0;
	var right = view.x > map.w - screen.w;
	var top = view.y < 0;
	var bottom = view.y > map.h - screen.h;

	var visibility = [[left && top, top, right && top],
	                  [left, false, right],
	                  [left && bottom, bottom, right && bottom]];

	for (var i = 0; i < 3; ++i)
		for (var j = 0; j < 3; ++j)
			if (visibility[i][j])
				for (var p in planets)
					planets[p].draw(ctxt, {x : (j-1) * map.w, y : (i-1) * map.h});
	
	for (var i = 0; i < 3; ++i)
		for (var j = 0; j < 3; ++j)
			if (visibility[i][j])
				for (var s in ships)
					ships[s].draw(ctxt, {x : (j-1) * map.w, y : (i-1) * map.h});

	for (var i = 0; i < 3; ++i)
		for (var j = 0; j < 3; ++j)
			if (visibility[i][j])
				for (var b in bullets)
					bullets[b].draw(ctxt, 255, {x : (j-1) * map.w, y : (i-1) * map.h});
}

function onConnect() {
	info("Connected to server");
}

function onDisconnect() {
	info("Aaargh! disconnected!");
}

function onMessage(msg) {
	switch (msg.type) {

		// When received bullet data.
	case 'bullets':
		bullets = [];
		for (var b in msg.bullets)
			bullets.push(new Bullet(msg.bullets[b]));
		break;

		// When received other ship data.
	case 'ships':
		serverShips = {};
		for (var s in msg.ships)
			serverShips[s] = new Ship(msg.ships[s]);
		lastUpdate = (new Date()).getTime();
		for (var s in ships)
			if (typeof serverShips[s] === 'undefined')
				delete ships[s];
		ships = {};

		// for (var s in msg.ships)
		// 	ships[s] = new Ship(msg.ships[s]);
		break;

		// When received planet data.
	case 'planets':
		planets = [];
		for (var p in msg.planets)
			planets.push(new Planet(msg.planets[p]));
		break;

		// When receiving our id from the server.
	case 'connected':
		id = msg.playerId;
		ready();
		break;

		// When another player joins.
	case 'player joins':
		break;

		// When another player dies.
	case 'player dies':
		break;

		// When another player leaves.
	case 'player quits':
		break;
	}
}
