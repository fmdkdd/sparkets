var socket;
var ctxt;

var width, height;

var ship = null;
var other_ships = [];
var planets = [];

var keys = [];

dir_inc = 0.1;
max_power = 3;
ship_speed = 0.3;
friction_decay = 0.97;

function init() {
	var host = 'ws://192.168.1.3:12345/websocket/server.php';

	try{
		socket = new WebSocket(host);
		socket.onmessage = receive;
	} catch(ex) { log(ex); }

	width = $('canvas').width;
	height = $('canvas').height;
	ctxt = $('canvas').getContext('2d');
}

function ready() {
	document.onkeydown = processKeyDown;
	document.onkeyup = processKeyUp;

	setInterval(update, 20);
}

function Ship(color) {
	this.pos = {x: Math.random()*width, y: Math.random()*height};
	this.vel = {x: 0, y: 0};
	this.dir = 0;
	this.color = color;
	this.fire_power = 1;
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
		try{ socket.send(msg); } catch (ex) { log(ex); }
	},

	send_new : function() {
		var msg = 'ns:' + [this.id, this.pos.x, this.pos.y, this.dir].join(':');
		log("sending: " + msg);
		try{ socket.send(msg); } catch (ex) { log(ex); }
	},

	move : function() {
		this.pos.x += this.vel.x;
		this.pos.y += this.vel.y;

    // friction
		this.vel.x *= friction_decay;
		this.vel.y *= friction_decay;

		// the map is a torus
		this.pos.x = this.pos.x < 0 ? width : this.pos.x;
		this.pos.x = this.pos.x > width ? 0 : this.pos.x;
		this.pos.y = this.pos.y < 0 ? height : this.pos.y;
		this.pos.y = this.pos.y > height ? 0 : this.pos.y;
	},
	
	draw : function() {
		var x = this.pos.x;
		var y = this.pos.y;
		var cos = Math.cos(this.dir);
		var sin = Math.sin(this.dir);

		var points = [[-7,10], [0,-10], [7,10], [0,6]];
		points = points.map(function (p) {
			return [(p[0]*cos - p[1]*sin), (p[0]*sin + p[1]*cos)];
		});

		ctxt.clearRect(x-15,y-15,28,28);

		ctxt.strokeStyle = this.color;
		ctxt.fillStyle = 'rgba(127, 157, 185, ' + (this.fire_power-1)/max_power + ')';
		ctxt.beginPath();
		ctxt.moveTo(x+points[3][0], y+points[3][1]);
		points.every(function(p) { ctxt.lineTo(x+p[0], y+p[1]); return true; });
		ctxt.closePath();
		ctxt.stroke();
		ctxt.fill();
	},

	fire : function() {
		new Bullet(this.pos.x, this.pos.y, this.dir, this.color, this);
	}
}

function Bullet(x, y, angle, color, owner) {
	this.owner = owner;
	this.power = owner.fire_power;
	this.acc_x = this.power*10*Math.sin(angle);
	this.acc_y = this.power*-10*Math.cos(angle);
	this.x = x + this.acc_x;
	this.y = y + this.acc_y
	this.color = color;

	if (owner.id == ship.id)
		this.send();

	this.step();
}

Bullet.prototype = {
	owner : null,

	send : function() {
		var msg = 'b:' + [this.owner.id, this.power].join(':');
		log("sending: " + msg);
		try{ socket.send(msg); } catch (ex) { log(ex); }
	},

	draw : function(nx, ny) {
		ctxt.strokeStyle = this.color;
		ctxt.beginPath();
		ctxt.moveTo(this.x, this.y);
		ctxt.lineTo(nx, ny);
		ctxt.closePath();
		ctxt.stroke();
	},

	step : function() {
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

		this.draw(nx, ny);

		this.x = nx;
		this.y = ny;
		
		this.acc_x = ax;
		this.acc_y = ay;

		if (this.collideWithShip(nx,ny)) {
			log("BOOM");
		} else if (this.collideWithPlanet(nx,ny)) {
			log("boom...");
		} else if (this.outOfBounds(nx,ny)) {
			log("byebye");
		} else {
			setTimeout(function(bullet) {bullet.step();}, 20, this);
		}
	},

	collideWithShip : function(x,y) {
		return other_ships.some(function(s) {
				return Math.abs(x - p.pos.x) < 10 && Math.abs(y - p.pos.y) < 10;
			});
	},

	collideWithPlanet : function(x,y) {
		return planets.some(function(p) {
			return Math.sqrt((p.x-x)*(p.x-x) + (p.y-y)*(p.y-y)) < p.force;
		});
	},

	outOfBounds : function(x,y) {
		return x < -1000 || x > 1000 || y < -1000 || y > 1000;
	}
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
		ctxt.strokeStyle = '#7F9DB9';
		ctxt.beginPath();
		ctxt.moveTo(this.x, this.y);
		ctxt.arc(this.x, this.y, this.force, 0, 2*Math.PI, false);
		ctxt.closePath();
		ctxt.stroke();
	}
}

function update() {
	ship.move();
	ship.send();
	ship.draw();
	
	processInputs();
}

function processInputs() {
	// left arrow : rotate to the left
	if(keys[37]) {
		ship.dir -= dir_inc;
		ship.send();
		ship.draw();
	}
	// right arrow : rotate to the right
	if(keys[39]) {
		ship.dir += dir_inc;
		ship.send();
		ship.draw();
	}
	// up arrow : thrust forward
	if(keys[38]) {
		ship.vel.x += Math.sin(ship.dir) * ship_speed;
		ship.vel.y -= Math.cos(ship.dir) * ship_speed;
		ship.send();
		ship.draw();
	}
	// spacebar : charge the bullet
	if(keys[32]) {
		ship.fire_power = Math.min(ship.fire_power + 0.1, max_power);
		ship.draw();
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
		ship.fire(true);
		ship.draw();
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
			other_ships[id] = new Ship('#000000');
		other_ships[id].pos.x = parseFloat(data[2]);
		other_ships[id].pos.y = parseFloat(data[3]);
		other_ships[id].dir = parseFloat(data[4]);
		other_ships[id].draw();
		break;
	case 'p':
		var p = new Planet(parseFloat(data[1]),
		                   parseFloat(data[2]),
		                   parseFloat(data[3])); 
		planets.push(p);
		p.draw();
		break;
	case 'ns':
		var s = new Ship('#000000');
		s.id = data[1];
		s.pos.x = parseFloat(data[2]);
		s.pos.y = parseFloat(data[3]);
		s.dir = parseFloat(data[4]);
		other_ships[s.id] = s;
		s.draw();
		ship.send();
		break;
	case 'id':
		ship = new Ship('#445785');
		ship.id = data[1];
		ship.draw();
		ship.send_new();
		ready();
		break;
	}
}

function quit() {
	try { socket.send("STOP"); } catch (ex) { log(ex); }
}

// Utilities
function $(id) { return document.getElementById(id); }
function log(msg) { console.log(msg); }
