var port = 12345;

var socket;

var ctxt;

var screen = {w : 0, h : 0};
var view = {x : 0, y : 0};
var map = {w : 2000, h : 2000};

var ship = null;
var other_ships = {};
var planets = [];
var bullets = [];

dir_inc = 0.1;
max_power = 3;
max_bullets = 5;
ship_speed = 0.3;
friction_decay = 0.97;

ship_color = '127, 185, 157';
enemy_color = '187, 127, 135';
planet_color = '127, 157, 185';

var keys = {};

function init() {
	try{
		socket = new io.Socket(null, {port:port});
		socket.connect();
		socket.on('message', onMessage);
		socket.on('connect', onConnect);
		socket.on('disconnect', onDisconnect);
	} catch(ex) { error(ex); }
	
	ctxt = document.getElementById('canvas').getContext("2d");

	$(window).resize(function(event) {
			screen.w = document.getElementById('canvas').width = window.innerWidth;
			screen.h = document.getElementById('canvas').height = window.innerHeight;
			center_view();
		});
	$(window).resize();
}

function ready() {
	document.onkeydown = processKeyDown;
	document.onkeyup = processKeyUp;
	setInterval(update, 20);
}

function Ship(color) {
	this.pos = {x: Math.random() * map.w, y: Math.random() * map.h};
	this.vel = {x: 0, y: 0};
	this.dir = Math.random() * 6.28318531;
	this.color = color;
	this.fire_power = 1;
	this.dead = false;

	center_view();
}

Ship.prototype = {
	id : null,
	pos : null,
	vel : null,
	dir : null,
	color : null,

	send : function() {
		var msg = { type: 'ship',
		            playerId: this.id,
		            ship: { x: this.pos.x,
		                    y: this.pos.y,
		                    dir: this.dir }};
		log("sending: " + msg);
		try{ socket.send(msg); } catch (ex) { error(ex); }
	},

	send_dead : function() {
		var msg = { type: 'player dies',
		            playerId: this.id };
		try{ socket.send(msg); } catch (ex) { error(ex); }	
	},

	move : function() {
		this.pos.x += this.vel.x;
		this.pos.y += this.vel.y;

		this.pos.x = this.pos.x < 0 ? map.w : this.pos.x;
		this.pos.x = this.pos.x > map.w ? 0 : this.pos.x;
		this.pos.y = this.pos.y < 0 ? map.h : this.pos.y;
		this.pos.y = this.pos.y > map.h ? 0 : this.pos.y;

		if(this == ship)
			center_view();

    // friction
		this.vel.x *= friction_decay;
		this.vel.y *= friction_decay;

		var os;
		if (os = collideWithOtherShip(this.pos.x, this.pos.y)) {
			this.explode();
			os.explode();
		} else if (collideWithPlanet(this.pos.x, this.pos.y)) {
			this.explode();
		}
	},

	update : function() {
		if (this.dead || this.explo_bits)
			return;
		this.move();
		this.send();
	},
	
	draw : function() {
		if (this.dead)
			return;
		else if (this.explo_bits != undefined)
			this.draw_explosion();
		else
			this.draw_ship();
	},

	draw_ship : function() {
		var x = this.pos.x - view.x;
		var y = this.pos.y - view.y;
		var cos = Math.cos(this.dir);
		var sin = Math.sin(this.dir);

		var points = [[-7,10], [0,-10], [7,10], [0,6]];
		points = points.map(function (p) {
			return [(p[0]*cos - p[1]*sin), (p[0]*sin + p[1]*cos)];
		});

		ctxt.strokeStyle = color(this.color);
		ctxt.fillStyle = color(this.color, (this.fire_power-1)/max_power);
		ctxt.beginPath();
		ctxt.moveTo(x+points[3][0], y+points[3][1]);
		points.every(function(p) { ctxt.lineTo(x+p[0], y+p[1]); return true; });
		ctxt.closePath();
		ctxt.stroke();
		ctxt.fill();
	},

	fire : function() {
		bullets.push(new Bullet(this.pos.x, this.pos.y, this.dir, this.color, this))
		if (bullets.length > max_bullets)
			bullets.shift();
	},

	explode : function() {
		this.send_dead();

		this.explo_bits = [];
		var vel = Math.max(this.vel.x, this.vel.y);

		for (var i=0; i < 200; ++i)
			this.explo_bits.push({
				x: this.pos.x - view.x,
				y: this.pos.y - view.y, 
				vx : .5*vel * (2*Math.random() -1),
				vy : .5*vel * (2*Math.random() -1),
			});
		this.explo_iter = 0;
	},

	draw_explosion : function() {
		var x = this.pos.x - view.x;
		var y = this.pos.y - view.y;

		ctxt.fillStyle = color(this.color, (50-this.explo_iter)/50);
		this.explo_bits.forEach(function(p) {
			ctxt.fillRect(p.x, p.y, 2, 2);
			p.x += p.vx + (2*Math.random() -1)/1.5;
			p.y += p.vy + (2*Math.random() -1)/1.5;
		});

		++this.explo_iter;
		if (this.explo_iter > 50) {
			this.dead = true;
			delete this.explo_bits;
			delete this.explo_iter;
		}
	}
};

function Bullet(x, y, angle, color, owner) {
	this.owner = owner;
	this.power = owner.fire_power;
	this.acc = {x : this.power*10*Math.sin(angle), y : this.power*-10*Math.cos(angle)};
	this.pos = {x : x, y : y};
	this.color = color;
	this.tail = [[this.pos.x, this.pos.y]];

	if (owner.id == ship.id)
		this.send();

	this.dead = false;
}

Bullet.prototype = {
	owner : null,
	pos : null,
	acc : null,

	send : function() {
		var msg = { type: 'bullet',
		            playerId: this.owner.id,
		            firePower : this.power };
		log("sending: " + msg);
		try{ socket.send(msg); } catch (ex) { error(ex); }
	},

	draw : function(nx, ny) {
		ctxt.strokeStyle = color(this.color);
		ctxt.beginPath();
		ctxt.moveTo(this.pos.x, this.pos.y);
		ctxt.lineTo(nx, ny);
		ctxt.closePath();
		ctxt.stroke();
	},

	draw_tail : function(alpha) {
		ctxt.strokeStyle = color(this.color, alpha);
		ctxt.beginPath();
		var x = this.tail[0][0] - view.x;
		var y = this.tail[0][1] - view.y;
		ctxt.moveTo(x, y);
		for (var i=1, len=this.tail.length; i < len; ++i) {
			x = this.tail[i][0] - view.x;
			y = this.tail[i][1] - view.y;
			ctxt.lineTo(x, y);
			ctxt.moveTo(x, y);		
		}
		ctxt.closePath();
		ctxt.stroke();
	},

	step : function() {
		if (this.dead)
			return;

		var x = this.pos.x;
		var y = this.pos.y;
		
		var ax = this.acc.x;
		var ay = this.acc.y;

		planets.forEach(function(p) {
			var d = (p.pos.x-x)*(p.pos.x-x) + (p.pos.y-y)*(p.pos.y-y);
			var d2 = 200 * p.force / (d * Math.sqrt(d));

			ax -= (x-p.pos.x) * d2;
			ay -= (y-p.pos.y) * d2;
		});

		var nx = x + ax;
		var ny = y + ay;

		this.tail.push([nx, ny]);

		this.pos.x = nx;
		this.pos.y = ny;
		
		this.acc.x = ax;
		this.acc.y = ay;

		var os;
		if (collideWithShip(nx,ny)) {
			log("You are dead.");
			ship.explode();
			this.dead = true;
		} else if (os = collideWithOtherShip(nx,ny)) {
			log("BOOM SHAKALAKA!");
			os.explode();
			this.dead = true;
		} else if (collideWithPlanet(nx,ny)) {
			log("miss...");
			this.dead = true;
		} else if (this.outOfBounds(nx,ny)) {
			log("byebye");
			this.dead = true;
		}
	},

	outOfBounds : function(x,y) {
		return x < 0 || x > map.w || y < 0 || y > map.h;
	}
};
	
function	collideWithShip(x,y) {
	if (ship.dead || ship.explo_bits)
		return false;

	if (Math.abs(x - ship.pos.x) < 10 && Math.abs(y - ship.pos.y) < 10) {
		ship.explode();
		return true;
	}
	return false;
}

function collideWithOtherShip(x,y) {
	for (var os in other_ships) {
		var s = other_ships[os];
		if (!s.dead && !s.explo_bits
		    && Math.abs(x - s.pos.x) < 10 && Math.abs(y - s.pos.y) < 10)
			return s;
	}
	return false;
}

function collideWithPlanet(x,y) {
	for (var op in planets) {
		var p = planets[op];
		if (Math.sqrt((p.pos.x-x)*(p.pos.x-x) + (p.pos.y-y)*(p.pos.y-y)) < p.force)
			return p;
	}
	return false;
}

function Planet(x, y, force) {
	this.pos = {x : x, y : y};
	this.force = force;
}

Planet.prototype = {
  pos : null,
	force : null,

	draw : function() {
		var x = this.pos.x - view.x;
		var y = this.pos.y - view.y;

		ctxt.strokeStyle = color(planet_color);
		ctxt.beginPath();
		ctxt.arc(x, y, this.force, 0, 2*Math.PI, false);
		ctxt.closePath();
		ctxt.stroke();
	}
}

function update() {
	ship.update();
	bullets.forEach(function(b) { b.step(); });
	redraw();
	
	processInputs();
}

function center_view() {
	if(ship != null) {
		view.x = ship.pos.x - screen.w / 2;
		view.y = ship.pos.y - screen.h / 2;
	}
}

function redraw() {
	ctxt.clearRect(0, 0, screen.w, screen.h);
	
	var len = bullets.length;
	bullets.forEach(function(b, idx) { b.draw_tail((idx+1)/len); });

	planets.forEach(function(p) { p.draw(); });

	ship.draw();
	for (var s in other_ships)
		other_ships[s].draw();

	draw_radar();

	draw_infinity();
}

function draw_radar() {
	for(var os in other_ships) {
		var dx = other_ships[os].pos.x - ship.pos.x;
		var dy = other_ships[os].pos.y - ship.pos.y;
		var d = Math.sqrt(dx*dx + dy*dy);
		var rx = dx / d * 50;
		var ry = dy / d * 50;
		
		ctxt.strokeStyle = color(planet_color);
		ctxt.beginPath();
		ctxt.arc(screen.w / 2 + rx, screen.h / 2 + ry, 2, 0, 2*Math.PI, false);
		ctxt.closePath();
		ctxt.stroke();
	}
}

function draw_infinity() {
	ctxt.strokeStyle = color(planet_color);
	for(var i = -1; i <= 1; ++i)
		for(var j = -1; j <= 1; ++j)
			if(i != 0 || j != 0)
				for(var p in planets)
				{
					var x = planets[p].pos.x + j * map.w - view.x;
					var y = planets[p].pos.y + i * map.h - view.y;

					ctxt.beginPath();
					ctxt.arc(x, y, planets[p].force, 0, 2*Math.PI, false);
					ctxt.closePath();
					ctxt.stroke();
				}
}

function processInputs() {
	// left arrow : rotate to the left
	if(keys[37]) {
		ship.dir -= dir_inc;
		ship.send();
	}
	// right arrow : rotate to the right
	if(keys[39]) {
		ship.dir += dir_inc;
		ship.send();
	}
	// up arrow : thrust forward
	if(keys[38]) {
		ship.vel.x += Math.sin(ship.dir) * ship_speed;
		ship.vel.y -= Math.cos(ship.dir) * ship_speed;
		ship.send();
	}
	// spacebar : charge the bullet
	if(keys[32]) {
		ship.fire_power = Math.min(ship.fire_power + 0.1, max_power);
	}
}

function processKeyDown(event) {
	keys[event.keyCode] = true;
}

function processKeyUp(event) {
	keys[event.keyCode] = false;

	// fire the bullet if the spacebar is released
	if(event.keyCode == 32)
	{
		ship.fire();
		ship.fire_power = 1;
	}
}

function onConnect() {
	log("Connected to server");
}

function onDisconnect() {
	log("Aaargh! disconnected!");
}

function onMessage(msg) {
	log("received: ");
	log(msg);

	switch (msg.type) {

		// When received bullet data.
	case 'bullet':
		var id = msg.playerId;
		other_ships[id].fire_power = msg.firePower;
		other_ships[id].fire();
		other_ships[id].fire_power = 1;
		break;

		// When received other ship data.
	case 'ship':
		var id = msg.playerId;
		other_ships[id].pos.x = msg.ship.x;
		other_ships[id].pos.y = msg.ship.y;
		other_ships[id].dir = msg.ship.dir;
		break;

		// When received planet data.
	case 'planet':
		var p = new Planet(msg.planet.x,
		                   msg.planet.y,
		                   msg.planet.size);
		planets.push(p);
		p.draw();
		break;

		// When receiving our id from the server.
	case 'connected':
		ship = new Ship(ship_color);
		ship.id = msg.playerId;
		ready();
		break;

		// When another player joins.
	case 'player joins':
		error("new player!");
		var s = new Ship(enemy_color);
		s.id = msg.playerId;
		other_ships[s.id] = s;
		break;

		// When another player leaves.
	case 'player dies':
	case 'player quits':
		delete other_ships[msg.playerId];
		break;
	}
}

function quit() {
	try { socket.send("STOP"); } catch (ex) { error(ex); }
}

// Utilities
function log(msg) { if (debug) console.log(msg); }
function error(msg) { console.log(msg); }
function color(rgb, alpha) {
	if (alpha == undefined)
		return 'rgb(' + rgb + ')';
	else
		return 'rgba(' + rgb + ',' + alpha + ')';
}

var debug = false;
