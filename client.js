var socket;

var ctxt;

var screen = {w : 0, h : 0};
var map = {w : 2000, h : 2000};
var view = {x : 0, y : 0};

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
	var host = 'ws://localhost:12345/websocket/server.php';

	try{
		socket = new WebSocket(host);
		socket.onmessage = receive;
	} catch(ex) { error(ex); }
	
	ctxt = document.getElementById('canvas').getContext("2d");

	$(window).resize(function(event) {
			screen.w = document.getElementById('canvas').width = window.innerWidth;
			screen.h = document.getElementById('canvas').height = window.innerHeight;

			if(ship != null)
				ship.centerView();
		});
	$(window).resize();
}

function ready() {
	document.onkeydown = processKeyDown;
	document.onkeyup = processKeyUp;

	$(window).unload(function(event) {
			ship.send_bye();
		});

	setInterval(update, 20);
}

function Ship(color) {
	this.pos = {x: Math.random() * map.w, y: Math.random() * map.h};
	this.vel = {x: 0, y: 0};
	this.dir = Math.random() * 6.28318531;
	this.color = color;
	this.fire_power = 1;
	this.dead = false;

	this.center_view();
}

Ship.prototype = {
	id : null,
	pos : null,
	vel : null,
	dir : null,
	color : null,

	send : function() {
		var msg = 's:' + [this.id, this.pos.x, this.pos.y, this.dir].join(':');
		log("sending: " + msg);
		try{ socket.send(msg); } catch (ex) { error(ex); }
	},

	send_new : function() {
		var msg = 'ns:' + [this.id, this.pos.x, this.pos.y, this.dir].join(':');
		log("sending: " + msg);
		try{ socket.send(msg); } catch (ex) { error(ex); }
	},

	send_bye : function () {
		var msg = 'bye:' + this.id;
		log("sending: " + msg);
		try{ socket.send(msg); } catch (ex) { error(ex); }
	},

	move : function() {
		this.pos.x += this.vel.x;
		this.pos.y += this.vel.y;

		this.pos.x = this.pos.x < 0 ? map.w : this.pos.x;
		this.pos.x = this.pos.x > map.w ? 0 : this.pos.x;
		this.pos.y = this.pos.y < 0 ? map.h : this.pos.y;
		this.pos.y = this.pos.y > map.h ? 0 : this.pos.y;

		this.center_view();

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

	center_view : function() {
		view.x = this.pos.x - screen.w / 2;
		view.y = this.pos.y - screen.h / 2;
	},

	fire : function() {
		bullets.push(new Bullet(this.pos.x, this.pos.y, this.dir, this.color, this))
		if (bullets.length > max_bullets)
			bullets.shift();
	},

	explode : function() {
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
	this.acc_x = this.power*10*Math.sin(angle);
	this.acc_y = this.power*-10*Math.cos(angle);
	this.x = x + this.acc_x;
	this.y = y + this.acc_y
	this.color = color;
	this.tail = [[this.x, this.y]];

	if (owner.id == ship.id)
		this.send();

	this.dead = false;
}

Bullet.prototype = {
	owner : null,

	send : function() {
		var msg = 'b:' + [this.owner.id, this.power].join(':');
		log("sending: " + msg);
		try{ socket.send(msg); } catch (ex) { error(ex); }
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

	draw : function(nx, ny) {
		ctxt.strokeStyle = color(this.color);
		ctxt.beginPath();
		ctxt.moveTo(this.x, this.y);
		ctxt.lineTo(nx, ny);
		ctxt.closePath();
		ctxt.stroke();
	},

	step : function() {
		if (this.dead)
			return;

		var x = this.x;
		var y = this.y;
		
		var ax = this.acc_x;
		var ay = this.acc_y;

		planets.forEach(function(p) {
			var d = (p.x-x)*(p.x-x) + (p.y-y)*(p.y-y);
			var d2 = 200 * p.force / (d * Math.sqrt(d));

			ax -= (x-p.x) * d2;
			ay -= (y-p.y) * d2;
		});

		var nx = x + ax;
		var ny = y + ay;

		this.tail.push([nx, ny]);

		this.x = nx;
		this.y = ny;
		
		this.acc_x = ax;
		this.acc_y = ay;

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
		} else {
			//setTimeout(function(bullet) {bullet.step();}, 20, this);
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
		if (Math.sqrt((p.x-x)*(p.x-x) + (p.y-y)*(p.y-y)) < p.force)
			return p;
	}
	return false;
}

function Planet(x, y, force) {
	this.x = x;
	this.y = y;
	this.force = force;
}

Planet.prototype = {
	x : null,
	y : null,
	force : null,

	draw : function() {
		for(var i = -1; i <= 1; ++i)
			for(var j = -1; j <= 1; ++j)
			{
				var x = this.x + j * map.w;
				var y = this.y + i * map.h;

				ctxt.strokeStyle = color(planet_color);
				ctxt.moveTo(x, y);
				ctxt.beginPath();
				ctxt.arc(x - view.x, y - view.y, this.force, 0, 2*Math.PI, false);
				ctxt.closePath();
				ctxt.stroke();
			}
	}
}

function update() {
	ship.update();
	bullets.forEach(function(b) { b.step(); });
	redraw();
	
	processInputs();
}

function redraw() {
	ctxt.clearRect(0, 0, screen.w, screen.h);
	
	var len = bullets.length;
	bullets.forEach(function(b, idx) { b.draw_tail((idx+1)/len); });

	planets.forEach(function(p) { p.draw(); });

	ship.draw();

	for (var s in other_ships)
		other_ships[s].draw();
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

function processKeyDown() {
	keys[event.keyCode] = true;
}

function processKeyUp() {
	keys[event.keyCode] = false;

	// fire the bullet if the spacebar is released
	if(event.keyCode == 32)
	{
		ship.fire();
		ship.fire_power = 1;
	}
}

function receive(msg) {
	log("received: " + msg.data);
	var data = msg.data.split(':');
	var type = data[0];
	switch (type) {
	case 'b':
		var id = data[1];
		var power = parseFloat(data[2]);
		other_ships[id].fire_power = power;
		other_ships[id].fire();
		other_ships[id].fire_power = 1;
		break;
	case 's':
		var id = data[1];
		if (other_ships[id] == undefined)
			other_ships[id] = new Ship(enemy_color);
		other_ships[id].pos.x = parseFloat(data[2]);
		other_ships[id].pos.y = parseFloat(data[3]);
		other_ships[id].dir = parseFloat(data[4]);
		break;
	case 'p':
		var p = new Planet(parseFloat(data[1]),
		                   parseFloat(data[2]),
		                   parseFloat(data[3])); 
		planets.push(p);
		p.draw();
		break;
	case 'ns':
		var s = new Ship(enemy_color);
		s.id = data[1];
		s.pos.x = parseFloat(data[2]);
		s.pos.y = parseFloat(data[3]);
		s.dir = parseFloat(data[4]);
		other_ships[s.id] = s;
		ship.send();
		break;
	case 'id':
		ship = new Ship(ship_color);
		ship.id = data[1];
		ship.send_new();
		ready();
		break;
	case 'bye':
		delete other_ships[data[1]];
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
