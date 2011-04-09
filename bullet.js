function Bullet(x, y, angle, color, owner) {
	this.owner = owner;
	this.power = owner.firePower;
	this.acc = {x : this.power*10*Math.sin(angle), y : this.power*-10*Math.cos(angle)};
	this.pos = {x : x, y : y};
	this.color = color;
	this.tail = [[this.pos.x, this.pos.y]];

	if (owner.id == ship.id)
		this.send();

	this.dead = false;
}

Bullet.prototype = {

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

	drawTail : function(alpha) {
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