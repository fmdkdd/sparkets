function Planet(x, y, force) {
	this.pos = {x : x, y : y};
	this.force = force;
}

Planet.prototype = {

	draw : function() {
		var x = this.pos.x - view.x;
		var y = this.pos.y - view.y;

		ctxt.strokeStyle = color(planetColor);
		ctxt.beginPath();
		ctxt.arc(x, y, this.force, 0, 2*Math.PI, false);
		ctxt.closePath();
		ctxt.stroke();
	}
};