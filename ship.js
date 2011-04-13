function Ship(color) {
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

	this.pos = { x : x, y : y };
	this.vel = { x: 0, y: 0 };
	this.dir = Math.random() * 2*Math.PI;
	this.color = color;
	this.firePower = 1.2;
	this.dead = false;
}

Ship.prototype = {

	send : function() {
		socket.send({ type: 'ship',
		              playerId: this.id,
		              ship: { x: this.pos.x,
		                      y: this.pos.y,
		                      dir: this.dir }});
	},

	sendDead : function() {
		socket.send({ type: 'player dies',
		              playerId: this.id });
	},

	move : function() {
		this.pos.x += this.vel.x;
		this.pos.y += this.vel.y;

		var x = this.pos.x;
		var y = this.pos.y;

		this.pos.x = this.pos.x < 0 ? map.w : this.pos.x;
		this.pos.x = this.pos.x > map.w ? 0 : this.pos.x;
		this.pos.y = this.pos.y < 0 ? map.h : this.pos.y;
		this.pos.y = this.pos.y > map.h ? 0 : this.pos.y;

		// friction
		this.vel.x *= frictionDecay;
		this.vel.y *= frictionDecay;
	},

	checkCollisions : function() {
		var x = this.pos.x;
		var y = this.pos.y;
		var os;
		if (os = collideWithOtherShip(x,y)) {
			this.explode();
			os.explode();
		} else if (collideWithPlanet(x, y)) {
			this.explode();
		}
	},

	checkCollisionWith : function(os) {
		if (this.isDead())
			return;

		if (Math.abs(this.pos.x - os.pos.x) < 10
		    && Math.abs(this.pos.y - os.pos.y) < 10) {
			this.explode();
			os.explode();
		}
	},

	isDead : function() {
		return this.dead || this.exploBits;
	},

	update : function() {
		if (this.isDead())
			return;

		this.move();
		this.send();
		this.checkCollisions();
	},
	
	draw : function(offset) {
		if (this.dead)
			return;
		else if (this.exploBits)
			this.drawExplosion(offset);
		else
			this.drawShip(offset);
	},

	drawShip : function(offset) {
		if(offset == undefined)
			offset = {x : 0, y : 0};

		var x = this.pos.x - view.x + offset.x;
		var y = this.pos.y - view.y + offset.y;
		var cos = Math.cos(this.dir);
		var sin = Math.sin(this.dir);

		var points = [[-7,10], [0,-10], [7,10], [0,6]];
		points = points.map(function (p) {
			return [(p[0]*cos - p[1]*sin), (p[0]*sin + p[1]*cos)];
		});

		ctxt.strokeStyle = color(this.color);
		ctxt.fillStyle = color(this.color, (this.firePower-1)/maxPower);
		ctxt.beginPath();
		ctxt.moveTo(x+points[3][0], y+points[3][1]);
		points.forEach(function(p) { ctxt.lineTo(x+p[0], y+p[1]); });
		ctxt.closePath();
		ctxt.stroke();
		ctxt.fill();
	},

	fire : function() {
		if (this.isDead())
			return;

		bullets.push(new Bullet(this));
		if (bullets.length > maxBullets)
			bullets.shift();

		this.firePower = 1.2;
	},

	explode : function() {
		if (this === ship)
			this.sendDead();

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

	drawExplosion : function(offset) {
		if(offset == undefined)
			offset = {x : 0, y : 0};

		var ox = -view.x + offset.x;
		var oy = -view.y + offset.y;

		ctxt.fillStyle = color(this.color,
		                       (maxExploFrame-this.exploFrame)/maxExploFrame);
		this.exploBits.forEach(function(p) {
			ctxt.fillRect(p.x + ox, p.y + oy, 4, 4);
			p.x += p.vx + (2*Math.random() -1)/1.5;
			p.y += p.vy + (2*Math.random() -1)/1.5;
		});

		++this.exploFrame;
		if (this.exploFrame > maxExploFrame) {
			this.dead = true;
			delete otherShips[this.id];
			delete this.exploBits;
			delete this.exploFrame;
		}
	}
};
