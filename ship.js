function Ship(color) {
	this.pos = {x: Math.random() * map.w, y: Math.random() * map.h};
	this.vel = {x: 0, y: 0};
	this.dir = Math.random() * 6.28318531;
	this.color = color;
	this.firePower = 1;
	this.dead = false;

	centerView();
}

Ship.prototype = {

	send : function() {
		if (this.dead || this.exploBits)
			return;

		var msg = { type: 'ship',
		            playerId: this.id,
		            ship: { x: this.pos.x,
		                    y: this.pos.y,
		                    dir: this.dir }};
		log("sending: " + msg);
		try{ socket.send(msg); } catch (ex) { error(ex); }
	},

	sendDead : function() {
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
			centerView();

		// friction
		this.vel.x *= frictionDecay;
		this.vel.y *= frictionDecay;

		var os;
		if (os = collideWithOtherShip(this.pos.x, this.pos.y)) {
			this.explode();
			os.explode();
		} else if (collideWithPlanet(this.pos.x, this.pos.y)) {
			this.explode();
		}
	},

	update : function() {
		if (this.dead || this.exploBits)
			return;

		this.move();
		this.send();
	},
	
	draw : function() {
		if (this.dead)
			return;
		else if (this.exploBits != undefined)
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
		points.every(function(p) { ctxt.lineTo(x+p[0], y+p[1]); return true; });
		ctxt.closePath();
		ctxt.stroke();
		ctxt.fill();
	},

	fire : function() {
		if (this.dead || this.exploBits)
			return;

		bullets.push(new Bullet(this.pos.x, this.pos.y, this.dir, this.color, this))
		if (bullets.length > maxBullets)
			bullets.shift();
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

		this.sendDead();
	},

	drawExplosion : function() {
		var x = this.pos.x - view.x;
		var y = this.pos.y - view.y;

		ctxt.fillStyle = color(this.color, (50-this.exploFrame)/50);
		this.exploBits.forEach(function(p) {
			ctxt.fillRect(p.x, p.y, 2, 2);
			p.x += p.vx + (2*Math.random() -1)/1.5;
			p.y += p.vy + (2*Math.random() -1)/1.5;
		});

		++this.exploFrame;
		if (this.exploFrame > 50) {
			this.dead = true;
			delete this.exploBits;
			delete this.exploFrame;
		}
	}
};