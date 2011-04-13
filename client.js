// Server
const port = 12345;
var socket;

// Graphics
var ctxt;
var screen = {w : 0, h : 0};
var view = {x : 0, y : 0};
var map = {w : 2000, h : 2000};

const shipColor = '127, 185, 157';
const enemyColor = '187, 127, 135';
const planetColor = '127, 157, 185';

// Game logic
var ship;
var otherShips = {};
var planets = [];
var bullets = [];

const dirInc = 0.1;
const maxPower = 3;
const maxBullets = 5;
const shipSpeed = 0.3;
const frictionDecay = 0.97;
const maxExploFrame = 50;

// Input
var keys = {};

function init() {
	// Connect to server and set callbacks.
	socket = new io.Socket('127.0.0.1', {port:port});
	socket.connect();
	socket.on('message', onMessage);
	socket.on('connect', onConnect);
	socket.on('disconnect', onDisconnect);

	// Setup canvas
	ctxt = document.getElementById('canvas').getContext("2d");

	$(window).resize(function(event) {
		screen.w = document.getElementById('canvas').width = window.innerWidth;
		screen.h = document.getElementById('canvas').height = window.innerHeight;
		centerView();
	});
	$(window).resize();
}

// Setup input callbacks and launch game loop.
function ready() {
	document.onkeydown = processKeyDown;
	document.onkeyup = processKeyUp;
	update();
}

// Game loop!
function update() {
	var start = (new Date()).getTime();

	processInputs();

	ship.update();
	bullets.forEach(function(b) { b.step(); });

	centerView();
	redraw();

	var diff = (new Date()).getTime() - start;
	setTimeout(update, 20-mod(diff, 20));
}

// Clear canvas and draw everything.
// Not efficient, but we don't have that many objects.
function redraw() {
	ctxt.clearRect(0, 0, screen.w, screen.h);
	ctxt.lineWidth = 4;
	ctxt.lineJoin = 'round';
	
	// Draw all bullets with decreasing opacity.
	var len = bullets.length;
	bullets.forEach(function(b, idx) { b.draw((idx+1)/len); });

	// Draw all planets.
	planets.forEach(function(p) { p.draw(); });

	// Draw all ships.
	ship.draw();
	for (var s in otherShips)
		otherShips[s].draw();

	drawRadar();

	drawInfinity();
}

function distance(x1, y1, x2, y2) {
	return Math.sqrt((x1-x2)*(x1-x2) + (y1-y2)*(y1-y2));
}

function collideWithShip(x,y) {
	if (ship.isDead())
		return false;

	if (Math.abs(x - ship.pos.x) < 10
	    && Math.abs(y - ship.pos.y) < 10)
		return true;

	return false;
}

function collideWithOtherShip(x,y) {
	for (var os in otherShips) {
		var s = otherShips[os];
		if (!s.isDead()
		    && Math.abs(x - s.pos.x) < 10
		    && Math.abs(y - s.pos.y) < 10)
			return s;
	}
	return false;
}

function collideWithPlanet(x,y) {
	for (var op in planets) {
		var p = planets[op];
		var px = p.pos.x;
		var py = p.pos.y;
		if (Math.sqrt((px-x)*(px-x) + (py-y)*(py-y)) < p.force)
			return p;
	}
	return false;
}

function centerView() {
	if (ship != null) {
		view.x = ship.pos.x - screen.w / 2;
		view.y = ship.pos.y - screen.h / 2;
	}
}

function drawRadar() {
	for (var os in otherShips) {
		var dx = otherShips[os].pos.x - ship.pos.x;
		var dy = otherShips[os].pos.y - ship.pos.y;
		var d = Math.sqrt(dx*dx + dy*dy);
		var rx = dx / d * 50;
		var ry = dy / d * 50;
		
		ctxt.strokeStyle = color(planetColor);
		ctxt.beginPath();
		ctxt.arc(screen.w / 2 + rx, screen.h / 2 + ry, 2, 0, 2*Math.PI, false);
		ctxt.closePath();
		ctxt.stroke();
	}
}

function drawInfinity() {
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
					planets[p].draw({x : (j-1) * map.w, y : (i-1) * map.h});
	
	for (var i = 0; i < 3; ++i)
		for (var j = 0; j < 3; ++j)
			if (visibility[i][j])
				for (var os in otherShips)
					otherShips[os].draw({x : (j-1) * map.w, y : (i-1) * map.h});

/*	for (var i = 0; i < 3; ++i)
		for (var j = 0; j < 3; ++j)
			if (visibility[i][j])
				for (var b in bullets)
				bullets[b].draw(255, {x : (j-1) * map.w, y : (i-1) * map.h});*/
}

function processInputs() {
	if (ship.isDead())
		return;

	// left arrow : rotate to the left
	if(keys[37]) {
		ship.dir -= dirInc;
		ship.send();
	}
	// right arrow : rotate to the right
	if(keys[39]) {
		ship.dir += dirInc;
		ship.send();
	}
	// up arrow : thrust forward
	if(keys[38]) {
		ship.vel.x += Math.sin(ship.dir) * shipSpeed;
		ship.vel.y -= Math.cos(ship.dir) * shipSpeed;
		ship.send();
	}
	// spacebar : charge the bullet
	if(keys[32]) {
		ship.firePower = Math.min(ship.firePower + 0.1, maxPower);
	}
}

function processKeyDown(event) {
	keys[event.keyCode] = true;
}

function processKeyUp(event) {
	keys[event.keyCode] = false;

	// fire the bullet if the spacebar is released
	if(event.keyCode === 32)
		ship.fire();
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
	case 'bullet':
		var os = otherShips[msg.playerId];
		os.firePower = msg.firePower;
		os.fire();
		break;

		// When received other ship data.
	case 'ship':
		var os = otherShips[msg.playerId];
		os.pos.x = msg.ship.x;
		os.pos.y = msg.ship.y;
		os.dir = msg.ship.dir;
		ship.checkCollisionWith(os);
		break;

		// When received planet data.
	case 'planet':
		var p = new Planet(msg.planet.x,
		                   msg.planet.y,
		                   msg.planet.size);
		planets.push(p);
		break;

		// When receiving our id from the server.
	case 'connected':
		ship = new Ship(shipColor);
		ship.id = msg.playerId;
		ready();
		break;

		// When another player joins.
	case 'player joins':
		var s = new Ship(enemyColor);
		s.id = msg.playerId;
		otherShips[s.id] = s;
		break;

		// When another player dies.
	case 'player dies':
		otherShips[msg.playerId].explode();
		break;

		// When another player leaves.
	case 'player quits':
		delete otherShips[msg.playerId];
		break;
	}
}
