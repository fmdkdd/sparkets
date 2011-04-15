(function() {
  var Bullet;
  Bullet = (function() {
    function Bullet(bullet) {
      this.owner = bullet.owner;
      this.pos = bullet.pos;
      this.accel = bullet.accel;
      this.power = bullet.power;
      this.dead = bullet.dead;
      this.color = bullet.color;
      this.points = bullets.points;
    }
    Bullet.prototype.draw = function(ctxt, alpha, offset) {
      var point, x, y, _i, _len;
      if (offset == null) {
        offset = {
          x: 0,
          y: 0
        };
      }
      ctxt.strokeStyle = color(this.color, alpha);
      ctxt.beginPath();
      x = this.points[0][0] - view.x + offset.x;
      y = this.points[0][1] - view.y + offset.y;
      ctxt.moveTo(x, y);
      for (_i = 0, _len = points.length; _i < _len; _i++) {
        point = points[_i];
        x = p[0] - view.x + offset.x;
        y = p[1] - view.y + offset.y;
        ctxt.lineTo(x, y);
      }
      return ctxt.stroke();
    };
    return Bullet;
  })();
}).call(this);
