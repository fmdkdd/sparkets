(function() {
  var Ship;
  Ship = (function() {
    function Ship(ship) {
      this.pos = ship.pos;
      this.dir = ship.dir;
      this.vel = ship.vel;
      this.firePower = ship.firePower;
      this.dead = ship.dead;
      this.exploBits = ship.exploBits;
      this.exploFrame = ship.exploFrame;
      this.color = ship.color;
    }
    Ship.prototype.isDead = function() {
      return this.dead === true || (this.exploBits != null);
    };
    Ship.prototype.draw = function(ctxt, offset) {
      if (this.dead === true) {
        ;
      } else if (this.exploBits != null) {
        return this.drawExplosion(ctxt, offset);
      } else {
        return this.drawShip(ctxt, offset);
      }
    };
    Ship.prototype.drawShip = function(ctxt, offset) {
      var cos, i, p, points, sin, x, y, _i, _len;
      if (offset == null) {
        offset = {
          x: 0,
          y: 0
        };
      }
      x = this.pos.x - view.x + offset.x;
      y = this.pos.y - view.y + offset.y;
      cos = Math.cos(this.dir);
      sin = Math.sin(this.dir);
      points = [[-7, 10]([0, -10]([7, 10]([0, 6])))];
      for (_i = 0, _len = points.length; _i < _len; _i++) {
        p = points[_i];
        p = [p[0] * cos - p[1] * sin, p[0] * sin + p[1] * cos];
      }
      ctxt.strokeStyle = color(this.color);
      ctxt.fillStyle = color(this.color, (this.firePower - 1) / maxPower);
      ctxt.beginPath();
      ctxt.moveTo(x + points[3][0], y + points[3][1]);
      for (i = 0; i <= 3; i++) {
        ctxt.lineTo(x + points[i][0], y + points[i][1]);
      }
      ctxt.closePath();
      ctxt.stroke();
      return ctxt.fill();
    };
    Ship.prototype.explode = function() {
      var i, vel, _results;
      this.exploBits = [];
      this.exploFrame = 0;
      vel = Math.max(this.vel.x, this.vel.y);
      _results = [];
      for (i = 0; i <= 200; i++) {
        _results.push(this.exploBits.push({
          x: this.pos.x,
          y: this.pos.y,
          vx: .5 * vel * (2 * Math.random() - 1),
          vy: .5 * vel * (2 * Math.random() - 1)
        }));
      }
      return _results;
    };
    Ship.prototype.drawExplosion = function(ctxt, offset) {
      var b, ox, oy, _i, _len, _ref, _results;
      if (offset == null) {
        offset = {
          x: 0,
          y: 0
        };
      }
      ox = -view.x + offset.x;
      oy = -view.y + offset.y;
      ctxt.fillStyle = color(this.color, (maxExploFrame - this.exploFrame) / maxExploFrame);
      _ref = this.exploBits;
      _results = [];
      for (_i = 0, _len = _ref.length; _i < _len; _i++) {
        b = _ref[_i];
        _results.push(ctxt.fillRect(b.x + ox, b.y + oy, 4, 4));
      }
      return _results;
    };
    return Ship;
  })();
}).call(this);
