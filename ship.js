function Ship(color) {
	this.pos = { x: Math.random() * map.w,
	             y: Math.random() * map.h };
	this.vel = { x: 0, y: 0 };
	this.dir = Math.random() * 2*Math.PI;
	this.color = color;
	this.firePower = 1;
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

		this.pos.x = x < 0 ? map.w : x;
		this.pos.x = x > map.w ? 0 : x;
		this.pos.y = y < 0 ? map.h : y;
		this.pos.y = y > map.h ? 0 : y;

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
			this.sendDead();
			os.explode();
		} else if (collideWithPlanet(x, y)) {
			this.explode();
			this.sendDead();
		}
	},

	checkCollisionWith : function(os) {
		if (this.isDead())
			return;

		if (Math.abs(this.pos.x - os.pos.x) < 10
		    && Math.abs(this.pos.y - os.pos.y) < 10) {
			this.explode();
			this.sendDead();
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
	
	draw : function() {
		if (this.dead)
			return;
		else if (this.exploBits)
			this.drawExplosion();
		else
			this.drawShip();
	},

	drawShip : function() {
		var x = this.pos.x - view.x;
		var y = this.pos.y - view.y;
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

		this.firePower = 1;
	},

	explode : function() {
		this.exploBits = [];
		var vel = Math.max(this.vel.x, this.vel.y);

		for (var i=0; i < 200; ++i)
			this.exploBits.push({
				x: this.pos.x - view.x,
				y: this.pos.y - view.y, 
				vx : .5*vel * (2*Math.random() -1),
				vy : .5*vel * (2*Math.random() -1),
			});
		this.exploFrame = 0;
	},

	drawExplosion : function() {
		var x = this.pos.x - view.x;
		var y = this.pos.y - view.y;

		ctxt.fillStyle = color(this.color,
		                       (maxExploFrame-this.exploFrame)/maxExploFrame);
		this.exploBits.forEach(function(p) {
			ctxt.fillRect(p.x, p.y, 2, 2);
			p.x += p.vx + (2*Math.random() -1)/1.5;
			p.y += p.vy + (2*Math.random() -1)/1.5;
		});

		++this.exploFrame;
		if (this.exploFrame > maxExploFrame) {
			this.dead = true;
			delete this.exploBits;
			delete this.exploFrame;
		}
	}
};