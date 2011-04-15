function Planet(planet) {
	this.pos = planet.pos;
	this.force = planet.force;
}

Planet.prototype = {

	draw : function(ctxt, offset) {
		if(offset == undefined)
			offset = {x : 0, y : 0};

		var px = this.pos.x + offset.x;
		var py = this.pos.y + offset.y;
		var f = this.force;

		if (!inView(px + f, py + f)
		    && !inView(px + f, py - f)
		    && !inView(px - f, py + f)
		    && !inView(px - f, py - f))
			return;

		var x = px - view.x;
		var y = py - view.y;

		ctxt.strokeStyle = color(planetColor);
		ctxt.beginPath();
		ctxt.arc(x, y, f, 0, 2*Math.PI, false);
		ctxt.stroke();
	}
};