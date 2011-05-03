(function() {
  var Bullet, Planet, distance, error, js, log, mod, randomColor;
  Bullet = (function() {
    function Bullet(owner) {
      var xdir, ydir;
      this.owner = owner;
      xdir = 10 * Math.sin(this.owner.dir);
      ydir = -10 * Math.cos(this.owner.dir);
      this.power = this.owner.firePower;
      this.pos = {
        x: this.owner.pos.x + xdir,
        y: this.owner.pos.y + ydir
      };
      this.accel = {
        x: this.owner.vel.x + this.power * xdir,
        y: this.owner.vel.y + this.power * ydir
      };
      this.dead = false;
      this.color = owner.color;
      this.points = [[this.pos.x, this.pos.y]];
    }
    Bullet.prototype.step = function() {
      var ax, ay, d, d2, p, warp, x, y, _i, _len;
      if (this.dead) {
        return;
      }
      x = this.pos.x;
      y = this.pos.y;
      ax = this.accel.x;
      ay = this.accel.y;
      for (_i = 0, _len = planets.length; _i < _len; _i++) {
        p = planets[_i];
        d = (p.pos.x - x) * (p.pos.x - x) + (p.pos.y - y) * (p.pos.y - y);
        d2 = 200 * p.force / (d * Math.sqrt(d));
        ax -= (x - p.pos.x) * d2;
        ay -= (y - p.pos.y) * d2;
      }
      this.pos.x = x + ax;
      this.pos.y = y + ay;
      this.accel.x = ax;
      this.accel.y = ay;
      this.points.push([this.pos.x, this.pos.y]);
      warp = false;
      if (this.pos.x < 0) {
        this.pos.x += map.w && (warp = true);
      }
      if (this.pos.x > map.w) {
        this.pos.x += -map.w && (warp = true);
      }
      if (this.pos.y < 0) {
        this.pos.y += map.h && (warp = true);
      }
      if (this.pos.y > map.h) {
        this.pos.y += -map.h && (warp = true);
      }
      if (warp) {
        this.points.push([this.pos.x, this.pos.y]);
      }
      return this.dead = this.collides();
    };
    Bullet.prototype.collides = function() {
      return this.collidesWithPlanet();
    };
    Bullet.prototype.collidesWithPlanet = function() {
      var p, px, py, x, y, _i, _len;
      x = this.pos.x;
      y = this.pos.y;
      for (_i = 0, _len = planets.length; _i < _len; _i++) {
        p = planets[_i];
        px = p.pos.x;
        py = p.pos.y;
        if (distance(px, py, x, y) < p.force) {
          return true;
        }
      }
      return false;
    };
    return Bullet;
  })();
  Planet = (function() {
    function Planet(x, y, force) {
      this.force = force;
      this.pos = {
        x: x,
        y: y
      };
    }
    return Planet;
  })();
  log = function(msg) {
    return console.log(msg);
  };
  error = function(msg) {
    return console.error(msg);
  };
  js = function(path) {
    return path.match(/js$/);
  };
  mod = function(x, n) {
    if (x > 0) {
      return x % n;
    } else {
      return mod(x + n, n);
    }
  };
  distance = function(x1, y1, x2, y2) {
    return Math.sqrt((x1 - x2) * (x1 - x2) + (y1 - y2) * (y1 - y2));
  };
  randomColor = function() {
    return Math.round(70 + Math.random() * 150) + ',' + Math.round(70 + Math.random() * 150) + ',' + Math.round(70 + Math.random() * 150);
  };
}).call(this);
,
        cannonHeat: true,
        dead: true,
        exploding: true,
        exploFrame: true
      };
      if (this.collidesWithPlanet()) {
        return this.spawn();
      }
    };
    Ship.prototype.move = function() {
      var x, y;
      x = this.pos.x;
      y = this.pos.y;
      this.pos.x += this.vel.x;
      this.pos.y += this.vel.y;
      this.pos.x = this.pos.x < 0 ? map.w : this.pos.x;
      this.pos.x = this.pos.x > map.w ? 0 : this.pos.x;
      this.pos.y = this.pos.y < 0 ? map.h : this.pos.y;
      this.pos.y = this.pos.y > map.h ? 0 : this.pos.y;
      this.vel.x *= frictionDecay;
      this.vel.y *= frictionDecay;
      if (this.pos.x !== x || this.pos.y !== y) {
        this.dirtyFields.pos = true;
        return this.dirtyFields.vel = true;
      }
    };
    Ship.prototype.collides = function() {
      return this.collidesWithOtherShip() || this.collidesWithBullet() || this.collidesWithPlanet();
    };
    Ship.prototype.collidesWithOtherShip = function() {
      var id, ship, _ref, _ref2;
      for (id in ships) {
        ship = ships[id];
        if (this.id !== ship.id && !ship.isDead() && !ship.isExploding() && (-10 < (_ref = this.pos.x - ship.pos.x) && _ref < 10) && (-10 < (_ref2 = this.pos.y - ship.pos.y) && _ref2 < 10)) {
          return true;
        }
      }
      return false;
    };
    Ship.prototype.collidesWithPlanet = function() {
      var p, px, py, x, y, _i, _len;
      x = this.pos.x;
      y = this.pos.y;
      for (_i = 0, _len = planets.length; _i < _len; _i++) {
        p = planets[_i];
        px = p.pos.x;
        py = p.pos.y;
        if (distance(px, py, x, y) < p.force) {
          return true;
        }
      }
      return false;
    };
    Ship.prototype.collidesWithBullet = function() {
      var b, x, y, _i, _len, _ref, _ref2;
      x = this.pos.x;
      y = this.pos.y;
      for (_i = 0, _len = bullets.length; _i < _len; _i++) {
        b = bullets[_i];
        if (!b.dead && (-10 < (_ref = x - b.pos.x) && _ref < 10) && (-10 < (_ref2 = y - b.pos.y) && _ref2 < 10)) {
          b.dead = true;
          return true;
        }
      }
      return false;
    };
    Ship.prototype.isExploding = function() {
      return this.exploding;
    };
    Ship.prototype.isDead = function() {
      return this.dead;
    };
    Ship.prototype.update = function() {
      if (this.isDead()) {
        return;
      }
      if (this.isExploding()) {
        return this.updateExplosion();
      } else {
        if (this.cannonHeat > 0) {
          --this.cannonHeat;
          this.dirtyFields.cannonHeat = true;
        }
        this.move();
        if (this.collides()) {
          return this.explode();
        }
      }
    };
    Ship.prototype.changes = function() {
      var changes, field, isDirty, _ref;
      changes = {};
      _ref = this.dirtyFields;
      for (field in _ref) {
        isDirty = _ref[field];
        if (isDirty) {
          changes[field] = this[field];
          this.dirtyFields[field] = false;
        }
      }
      return changes;
    };
    Ship.prototype.fire = function() {
      if (this.isDead() || this.isExploding() || this.cannonHeat > 0) {
        return;
      }
      bullets.push(new Bullet(this));
      if (bullets.length > maxBullets) {
        bullets.shift();
      }
      this.firePower = minFirepower;
      this.cannonHeat = cannonCooldown;
      this.dirtyFields.firePower = true;
      return this.dirtyFields.cannonHeat = true;
    };
    Ship.prototype.explode = function() {
      this.exploding = true;
      this.exploFrame = 0;
      this.dirtyFields.exploding = true;
      return this.dirtyFields.exploFrame = true;
    };
    Ship.prototype.updateExplosion = function() {
      ++this.exploFrame;
      if (this.exploFrame > maxExploFrame) {
        this.exploding = false;
        this.dead = true;
        this.exploFrame = null;
        this.dirtyFields.exploding = true;
        this.dirtyFields.dead = true;
      }
      return this.dirtyFields.exploFrame = true;
    };
    return Ship;
  })();
  log = function(msg) {
    return console.log(msg);
  };
  error = function(msg) {
    return console.error(msg);
  };
  js = function(path) {
    return path.match(/js$/);
  };
  mod = function(x, n) {
    if (x > 0) {
      return x % n;
    } else {
      return mod(x + n, n);
    }
  };
  distance = function(x1, y1, x2, y2) {
    return Math.sqrt((x1 - x2) * (x1 - x2) + (y1 - y2) * (y1 - y2));
  };
  randomColor = function() {
    return Math.round(70 + Math.random() * 150) + ',' + Math.round(70 + Math.random() * 150) + ',' + Math.round(70 + Math.random() * 150);
  };
}).call(this);
 = {
        pos: true,
        vel: true,
        dir: true,
        firePower: true,
        cannonHeat: true,
        dead: true,
        exploding: true,
        exploFrame: true
      };
      if (this.collidesWithPlanet()) {
        return this.spawn();
      }
    };
    Ship.prototype.move = function() {
      var x, y;
      x = this.pos.x;
      y = this.pos.y;
      this.pos.x += this.vel.x;
      this.pos.y += this.vel.y;
      this.pos.x = this.pos.x < 0 ? map.w : this.pos.x;
      this.pos.x = this.pos.x > map.w ? 0 : this.pos.x;
      this.pos.y = this.pos.y < 0 ? map.h : this.pos.y;
      this.pos.y = this.pos.y > map.h ? 0 : this.pos.y;
      this.vel.x *= frictionDecay;
      this.vel.y *= frictionDecay;
      if (this.pos.x !== x || this.pos.y !== y) {
        this.dirtyFields.pos = true;
        return this.dirtyFields.vel = true;
      }
    };
    Ship.prototype.collides = function() {
      return this.collidesWithOtherShip() || this.collidesWithBullet() || this.collidesWithPlanet();
    };
    Ship.prototype.collidesWithOtherShip = function() {
      var id, ship, _ref, _ref2;
      for (id in ships) {
        ship = ships[id];
        if (this.id !== ship.id && !ship.isDead() && !ship.isExploding() && (-10 < (_ref = this.pos.x - ship.pos.x) && _ref < 10) && (-10 < (_ref2 = this.pos.y - ship.pos.y) && _ref2 < 10)) {
          return true;
        }
      }
      return false;
    };
    Ship.prototype.collidesWithPlanet = function() {
      var p, px, py, x, y, _i, _len;
      x = this.pos.x;
      y = this.pos.y;
      for (_i = 0, _len = planets.length; _i < _len; _i++) {
        p = planets[_i];
        px = p.pos.x;
        py = p.pos.y;
        if (distance(px, py, x, y) < p.force) {
          return true;
        }
      }
      return false;
    };
    Ship.prototype.collidesWithBullet = function() {
      var b, x, y, _i, _len, _ref, _ref2;
      x = this.pos.x;
      y = this.pos.y;
      for (_i = 0, _len = bullets.length; _i < _len; _i++) {
        b = bullets[_i];
        if (!b.dead && (-10 < (_ref = x - b.pos.x) && _ref < 10) && (-10 < (_ref2 = y - b.pos.y) && _ref2 < 10)) {
          b.dead = true;
          return true;
        }
      }
      return false;
    };
    Ship.prototype.isExploding = function() {
      return this.exploding;
    };
    Ship.prototype.isDead = function() {
      return this.dead;
    };
    Ship.prototype.update = function() {
      if (this.isDead()) {
        return;
      }
      if (this.isExploding()) {
        return this.updateExplosion();
      } else {
        if (this.cannonHeat > 0) {
          --this.cannonHeat;
          this.dirtyFields.cannonHeat = true;
        }
        this.move();
        if (this.collides()) {
          return this.explode();
        }
      }
    };
    Ship.prototype.changes = function() {
      var changes, field, isDirty, _ref;
      changes = {};
      _ref = this.dirtyFields;
      for (field in _ref) {
        isDirty = _ref[field];
        if (isDirty) {
          changes[field] = this[field];
          this.dirtyFields[field] = false;
        }
      }
      return changes;
    };
    Ship.prototype.fire = function() {
      if (this.isDead() || this.isExploding() || this.cannonHeat > 0) {
        return;
      }
      bullets.push(new Bullet(this));
      if (bullets.length > maxBullets) {
        bullets.shift();
      }
      this.firePower = minFirepower;
      this.cannonHeat = cannonCooldown;
      this.dirtyFields.firePower = true;
      return this.dirtyFields.cannonHeat = true;
    };
    Ship.prototype.explode = function() {
      this.exploding = true;
      this.exploFrame = 0;
      this.dirtyFields.exploding = true;
      return this.dirtyFields.exploFrame = true;
    };
    Ship.prototype.updateExplosion = function() {
      ++this.exploFrame;
      if (this.exploFrame > maxExploFrame) {
        this.exploding = false;
        this.dead = true;
        this.exploFrame = null;
        this.dirtyFields.exploding = true;
        this.dirtyFields.dead = true;
      }
      return this.dirtyFields.exploFrame = true;
    };
    return Ship;
  })();
  log = function(msg) {
    return console.log(msg);
  };
  error = function(msg) {
    return console.error(msg);
  };
  js = function(path) {
    return path.match(/js$/);
  };
  mod = function(x, n) {
    if (x > 0) {
      return x % n;
    } else {
      return mod(x + n, n);
    }
  };
  distance = function(x1, y1, x2, y2) {
    return Math.sqrt((x1 - x2) * (x1 - x2) + (y1 - y2) * (y1 - y2));
  };
  randomColor = function() {
    return Math.round(70 + Math.random() * 150) + ',' + Math.round(70 + Math.random() * 150) + ',' + Math.round(70 + Math.random() * 150);
  };
  launch();
}).call(this);
