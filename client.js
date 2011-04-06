var socket;
var ctxt;

var width, height;

var ship = null;
var other_ships = [];
var planets = [];

dir_inc = 0.1;

function init() {
	var host = 'ws://172.16.21.220:12345/websocket/server.php';

	try{
		socket = new WebSocket(host);
		socket.onmessage = receive;
	} catch(ex) { log(ex); }

	document.onkeydown = processInput;

	width = $('canvas').width;
	height = $('canvas').height;
	ctxt = $('canvas').getContext('2d');
}

function Ship(color) {
	this.pos = {x: Math.random()*width, y: Math.random()*height};
	this.dir = 0;
	this.color = color;
}

Ship.prototype = {
	id : null,
	pos : null,
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
		this.pos.x += Math.sin(this.dir) * 5;
		this.pos.y -= Math.cos(this.dir) * 5;
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
		ctxt.beginPath();
		ctxt.moveTo(x+points[3][0], y+points[3][1]);
		points.every(function(p) { ctxt.lineTo(x+p[0], y+p[1]); return true; });
		ctxt.closePath();
		ctxt.stroke();
	},

	fire : function() {
		new Bullet(this.pos.x, this.pos.y, this.dir, this.color, this);
	}
}

function Bullet(x, y, angle, color, owner) {
	this.owner = owner;
	this.acc_x = 10*Math.sin(angle);
	this.acc_y = -10*Math.cos(angle);
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
		var msg = 'b:' + this.owner.id; 
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

function processInput(event) {
	switch (event.which) {
	case 37:
		ship.dir -= dir_inc;
		ship.send();
		ship.draw();
		break;
	case 39:
		ship.dir += dir_inc;
		ship.send();
		ship.draw();
		break;
	case 38:
		ship.move();
		ship.send();
		ship.draw();
		break;
	case 32 :
		ship.fire();
		ship.draw();
		break;
	}
}

function receive(msg) {
	log("received: " + msg.data);
	var data = msg.data.split(':');
	var type = data[0];
	switch (type) {
	case 'b':
		var id = data[1];
		other_ships[id].fire();
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
		break;
	}
}

function quit() {
	try { socket.send("STOP"); } catch (ex) { log(ex); }
}

// Utilities
function $(id) { return document.getElementById(id); }
function log(msg) { console.log(msg); }


