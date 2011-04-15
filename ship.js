function Ship(ship) {
	this.pos = ship.pos;
	this.vel = ship.vel;
	this.dir = ship.dir;
	this.color = ship.color;
	this.firePower = ship.firePower;
	this.dead = ship.dead;
	this.exploBits = ship.exploBits;
	this.exploFrame = ship.exploFrame;
}

Ship.prototype = {

	isDead : function() {
		return this.dead || this.exploBits;
	},

	
	draw : function(ctxt, offset) {
		if (this.dead)
			return;
		else if (this.exploBits)
			this.drawExplosion(ctxt, offset);
		else
			this.drawShip(ctxt, offset);
	},

	drawShip : function(ctxt, offset) {
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
		for (var p in points)
			ctxt.lineTo(x+points[p][0], y+points[p][1]);
		ctxt.closePath();
		ctxt.stroke();
		ctxt.fill();
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

	drawExplosion : function(ctxt, offset) {
		if(offset == undefined)
			offset = {x : 0, y : 0};

		var ox = -view.x + offset.x;
		var oy = -view.y + offset.y;

		ctxt.fillStyle = color(this.color,
		                       (maxExploFrame-this.exploFrame)/maxExploFrame);
		this.exploBits.forEach(function(p) {
			ctxt.fillRect(p.x + ox, p.y + oy, 4, 4);
		});
	}
};
