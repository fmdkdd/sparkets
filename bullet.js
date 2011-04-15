function Bullet(bullet) {
	this.owner = bullet.owner;
	this.pos = bullet.pos;

	this.power = bullet.power;

	this.accel = bullet.accel;

	this.color = bullet.color;
	this.points = bullet.points;

	this.dead = bullet.dead;
}

Bullet.prototype = {

	draw : function(ctxt, alpha, offset) {
		if(offset == undefined)
			offset = {x : 0, y : 0};

		var points = this.points;

		ctxt.strokeStyle = color(this.color, alpha);
		ctxt.beginPath();

		var x = points[0][0] - view.x + offset.x;
		var y = points[0][1] - view.y + offset.y;
		ctxt.moveTo(x, y);

		for (var i=1, len=points.length; i < len; ++i) {
			x = points[i][0] - view.x + offset.x;
			y = points[i][1] - view.y + offset.y;

			// don't draw the segment if a map-warping occured
			if(Math.abs(points[i][0] - points[i-1][0]) < map.w / 2 &&
			   Math.abs(points[i][1] - points[i-1][1]) < map.h / 2) {
				ctxt.lineTo(x, y);
			}
			else {
				// start another line at the the other side of the map
				ctxt.stroke();
				ctxt.beginPath();
				ctxt.moveTo(x, y);
			}
		}

		ctxt.stroke();
	},
};