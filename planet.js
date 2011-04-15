(function() {
  var Planet;
  Planet = (function() {
    function Planet(planet) {
      this.pos = planet.pos;
      this.force = planet.force;
    }
    Planet.prototype.draw = function(ctxt, offset) {
      var f, px, py, x, y;
      if (offset == null) {
        offset = {
          x: 0,
          y: 0
        };
      }
      px = this.pos.x + offset.x;
      py = this.pos.y + offset.y;
      f = this.force;
      if (!inView(px + f, py + f && !inView(px + f, py - f && !inView(px - f, py + f && !inView(px - f, py - f))))) {
        return;
      }
      x = px - view.x;
      y = py - view.y;
      ctxt.strokeStyle = color(planetColor);
      ctxt.beginPath();
      ctxt.arc(x, y, f, 0, 2 * Math.PI, false);
      return ctxt.stroke();
    };
    return Planet;
  })();
}).call(this);
