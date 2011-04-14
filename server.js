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
		// Allow only these six files.
	case '/client.html':
	case '/client.js':
	case '/ship.js':
	case '/bullet.js':
	case '/planet.js':
	case '/utils.js':
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

const dirInc = 0.1;
const maxPower = 3;
const minFirepower = 1.3;
const cannonCooldown = 20;
const maxBullets = 5;
const shipSpeed = 0.3;
const frictionDecay = 0.97;
const maxExploFrame = 50;

var map = {w : 2000, h : 2000};

var players = {};
var ships = {};
var bullets = [];
var planets = initPlanets();

update();

function onConnect(player) {
	// Send list of connected players.
	for (var p in players)
		player.send({ type: 'player list',
		              playerId: players[p] });

	// Add new player to player list.
	var id = player.sessionId;
	players[id] = {};
	players[id].id = id;
	players[id].keys = {};

	// Create ship.
	ships[id] = new Ship(id);

	// Send the playfield.
	player.send({ type: 'planets',
	              planets: planets });

	// Send ships.
	player.send({ type: 'ships',
	              ships: ships });

	// Good news!
	player.send({ type: 'connected',
	              playerId: id });

	// Poke all other players.
	player.broadcast({ type: 'player joins',
	                   playerId: id });
}

function onMessage(msg, player) {
	var id = msg.playerId;

	// Receive only player input.
	switch (msg.type) {
 	case 'key down':
		processKeyDown(msg.playerId, msg.key);
		break;

 	case 'key up':
		processKeyUp(msg.playerId, msg.key);
		break;
	}
}

function processKeyDown(id, key) {
	players[id].keys[key] = true;
}

function processKeyUp(id, key) {
	players[id].keys[key] = false;

	// fire the bullet if the spacebar is released
	if(key === 32)
		ships[id].fire();
}

function processInputs(id) {
	var keys = players[id].keys;
	var ship = ships[id];
	
	if (typeof ship === 'undefined' || ship.isDead())
		return;

	// left arrow : rotate to the left
	if(keys[37])
		ship.dir -= dirInc;

	// right arrow : rotate to the right
	if(keys[39])
		ship.dir += dirInc;

	// up arrow : thrust forward
	if(keys[38]) {
		ship.vel.x += Math.sin(ship.dir) * shipSpeed;
		ship.vel.y -= Math.cos(ship.dir) * shipSpeed;
	}

	// spacebar : charge the bullet
	if(keys[32])
		ship.firePower = Math.min(ship.firePower + 0.1, maxPower);
}

function update() {
	var start = (new Date()).getTime();

	for (var p in players)
		processInputs(players[p].id);

	updateBullets();
	updateShips();

	var diff = (new Date()).getTime() - start;
	setTimeout(update, 20-mod(diff, 20));
}

function updateShips() {
	for (var s in ships)
		ships[s].update();
	io.broadcast({ type: 'ships',
	               ships: ships });
}

function updateBullets() {
	bullets.forEach(function(b) { b.step(); });
	io.broadcast({ type: 'bullets',
	               bullets: bullets });
}

function onDisconnect(player) {
	// Purge from list.
	var id = player.sessionId;
	delete players[id];
	delete ships[id];

	// Tell everyone.
	player.broadcast({ type: 'player quits',
	                   playerId: id });
}

function initPlanets() {
	var planets = [];
	for (var i=0; i < 35; ++i)
		planets.push(new Planet(Math.random()*2000,
		                        Math.random()*2000,
		                        50+Math.random()*50));

	return planets;
}

//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
// Ship

function Ship(id) {
	// Find a suitable position for the ship.
	do
	{
		var x = Math.random() * map.w;
		var y = Math.random() * map.h;
		var isInsidePlanet = false;

		for(var i = 0, len = planets.length; i < len; ++i)
			if(distance(planets[i].pos.x, planets[i].pos.y, x, y) < planets[i].force) {
				isInsidePlanet = true;
				break;
			}
	} while(isInsidePlanet=== true);

	this.id = id;
	this.pos = { x : x, y : y };
	this.vel = { x: 0, y: 0 };
	this.dir = Math.random() * 2*Math.PI;
	this.color = randomColor();
	this.firePower = minFirepower;
	this.cannonHeat = 0;
	this.dead = false;
}

Ship.prototype = {

	move : function() {
		this.pos.x += this.vel.x;
		this.pos.y += this.vel.y;

		this.pos.x = this.pos.x < 0 ? map.w : this.pos.x;
		this.pos.x = this.pos.x > map.w ? 0 : this.pos.x;
		this.pos.y = this.pos.y < 0 ? map.h : this.pos.y;
		this.pos.y = this.pos.y > map.h ? 0 : this.pos.y;

		// friction
		this.vel.x *= frictionDecay;
		this.vel.y *= frictionDecay;
	},

	collides : function() {
		return this.collidesWithOtherShip()
			|| this.collidesWithPlanet()
			|| this.collidesWithBullet();
	},

	collidesWithOtherShip : function() {
		var x = this.pos.x;
		var y = this.pos.y;

		for (var s in ships) {
			var ship = ships[s];
			if (this !== ship
			    && Math.abs(x - ship.pos.x) < 10
			    && Math.abs(y - ship.pos.y) < 10)
				return true;
		}
		return false;
	},

	collidesWithPlanet : function() {
		var x = this.pos.x;
		var y = this.pos.y;

		return planets.some(function(p) {
			var px = p.pos.x; var py = p.pos.y;
			return (Math.sqrt((px-x)*(px-x) + (py-y)*(py-y)) < p.force);
		});
	},

	collidesWithBullet : function() {
		var x = this.pos.x;
		var y = this.pos.y;

		for (var i=0, l=bullets.length; i<l; ++i) {
			var b = bullets[i];
			if (!b.dead && Math.abs(x - b.pos.x) < 10
			    && Math.abs(y - b.pos.y) < 10) {
				b.dead = true;
				return true;
			}
		}
		return false;
	},

	isDead : function() {
		return this.dead || this.exploBits;
	},

	update : function() {
		if (this.dead)
			return;

		else if (this.exploBits)
			this.updateExplosion();

		else {
			--this.cannonHeat;
			this.move();
			if (this.collides())
				this.explode();
		}
	},
	
	fire : function() {
		if (this.isDead())
			return;

		if (this.cannonHeat > 0)
			return;

		bullets.push(new Bullet(this));
		if (bullets.length > maxBullets)
			bullets.shift();

		this.firePower = minFirepower;
		this.cannonHeat = cannonCooldown;
	},

	explode : function() {
		this.exploBits = [];
		var vel = Math.max(this.vel.x, this.vel.y);

		for (var i=0; i < 200; ++i)
			this.exploBits.push({
				x: this.pos.x,
				y: this.pos.y,
				vx : .5*vel * (2*Math.random() -1),
				vy : .5*vel * (2*Math.random() -1),
			});
		this.exploFrame = 0;
	},

	updateExplosion : function() {
		this.exploBits.forEach(function(p) {
			p.x += p.vx + (2*Math.random() -1)/1.5;
			p.y += p.vy + (2*Math.random() -1)/1.5;
		});

		++this.exploFrame;
		if (this.exploFrame > maxExploFrame) {
			this.dead = true;
			delete ships[this.id];
			delete this.exploBits;
			delete this.exploFrame;
		}
	},
};

//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
// Bullet

function Bullet(owner) {
	this.owner = owner;
	this.pos = { x : owner.pos.x,
	             y : owner.pos.y };

	this.power = owner.firePower;

	this.accel = { x : owner.vel.x + 10*this.power*Math.sin(owner.dir),
	               y : owner.vel.y + -10*this.power*Math.cos(owner.dir) };

	this.color = owner.color;
	this.points = [[this.pos.x + 10*Math.sin(owner.dir),
	                this.pos.y - 10*Math.cos(owner.dir)]];

	this.dead = false;
}

Bullet.prototype = {

	step : function() {
		if (this.dead)
			return;

		// Compute new position from acceleration and gravity of all
		// planets.
		var x = this.pos.x;
		var y = this.pos.y;
		
		var ax = this.accel.x;
		var ay = this.accel.y;

		planets.forEach(function(p) {
			var d = (p.pos.x-x)*(p.pos.x-x) + (p.pos.y-y)*(p.pos.y-y);
			var d2 = 200 * p.force / (d * Math.sqrt(d));

			ax -= (x-p.pos.x) * d2;
			ay -= (y-p.pos.y) * d2;
		});

		var nx = x + ax;
		var ny = y + ay;

		this.points.push([nx, ny]);

		this.pos.x = nx;
		this.pos.y = ny;
		
		this.accel.x = ax;
		this.accel.y = ay;

		// warp the bullet around the map
		this.pos.x = this.pos.x < 0 ? map.w : this.pos.x;
		this.pos.x = this.pos.x > map.w ? 0 : this.pos.x;
		this.pos.y = this.pos.y < 0 ? map.h : this.pos.y;
		this.pos.y = this.pos.y > map.h ? 0 : this.pos.y;

		if (this.outOfBounds() || this.collides())
			this.dead = true;
	},

	collides : function() {
		return this.collidesWithPlanet();
	},

	collidesWithPlanet : function() {
		var x = this.pos.x;
		var y = this.pos.y;

		return planets.some(function(p) {
			var px = p.pos.x; var py = p.pos.y;
			return (Math.sqrt((px-x)*(px-x) + (py-y)*(py-y)) < p.force);
		});
	},

	outOfBounds : function() {
		var x = this.pos.x;
		var y = this.pos.y;
		return x < 0 || x > map.w || y < 0 || y > map.h;
	}
};

//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
// Planet

function Planet(x, y, force) {
	this.pos = {x : x, y : y};
	this.force = force;
}

//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
// Utilities
function log(msg) { console.log(msg); };
function error(msg) { console.error(msg); };
function js(path) { return path.match(/js$/) };

// Stupid % operator
function mod(x, n) {
	return x > 0 ? x%n : n+(x%n);
}

function distance(x1, y1, x2, y2) {
	return Math.sqrt((x1-x2)*(x1-x2) + (y1-y2)*(y1-y2));
}

function randomColor() {
	return Math.round(70 + Math.random()*150)
		+ ','
		+ Math.round(70 + Math.random()*150)
		+ ','
		+ Math.round(70 + Math.random()*150);
}