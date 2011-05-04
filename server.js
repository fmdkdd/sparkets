(function() {
  var Bullet, Mine, Planet, Ship, bullets, cannonCooldown, color, dirInc, distance, frictionDecay, fs, http, info, initPlanets, io, isEmptyObject, js, launch, log, map, maxBullets, maxExploFrame, maxPower, minFirepower, mines, mod, planets, players, port, processInputs, processKeyDown, processKeyUp, randomColor, send404, server, shipSpeed, ships, update, updateBullets, updateMines, updateShips, url, warn;
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
  Mine = (function() {
    function Mine(ship) {
      this.state = 0;
      this.playerId = ship.id;
      this.pos = {
        x: ship.pos.x,
        y: ship.pos.y
      };
      this.color = ship.color;
      this.radius = 10;
      this.explosionRadius = 60;
      this.countdown = 500;
      this.lastUpdate = (new Date).getTime();
    }
    Mine.prototype.activate = function() {
      return this.state = 1;
    };
    Mine.prototype.explode = function() {
      this.state = 2;
      return this.countdown = 500;
    };
    Mine.prototype.die = function() {
      return this.state = 3;
    };
    Mine.prototype.update = function() {
      var diff, id, now, ship, _ref, _ref2, _ref3, _ref4;
      now = (new Date).getTime();
      diff = now - this.lastUpdate;
      if (this.state === 0) {
        this.countdown -= diff;
        if (this.countdown <= 0) {
          this.activate();
        }
      } else if (this.state === 1) {
        for (id in ships) {
          ship = ships[id];
          if (!ship.isDead() && !ship.isExploding() && (-10 < (_ref = this.pos.x - ship.pos.x) && _ref < 10) && (-10 < (_ref2 = this.pos.y - ship.pos.y) && _ref2 < 10)) {
            this.explode();
          }
        }
      } else if (this.state === 2) {
        this.countdown -= diff;
        if (this.countdown <= 0) {
          this.die();
        }
        for (id in ships) {
          ship = ships[id];
          if (!ship.isDead() && !ship.isExploding() && (-this.explosionRadius < (_ref3 = this.pos.x - ship.pos.x) && _ref3 < this.explosionRadius) && (-this.explosionRadius < (_ref4 = this.pos.y - ship.pos.y) && _ref4 < this.explosionRadius)) {
            ship.explode();
          }
        }
      }
      return this.lastUpdate = now;
    };
    return Mine;
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
  port = 12345;
  http = require('http');
  io = require('socket.io');
  url = require('url');
  fs = require('fs');
  server = http.createServer(function(req, res) {
    var path;
    path = url.parse(req.url).pathname;
    switch (path) {
      case '/client.html':
      case '/client.js':
      case '/jquery.js':
        return fs.readFile(__dirname + path, function(err, data) {
          if (err != null) {
            return send404(res);
          }
          res.writeHead(200, {
            'Content-Type': js(path) ? 'text/javascript' : 'text/html'
          });
          res.write(data, 'utf8');
          return res.end();
        });
      default:
        return send404(res);
    }
  });
  send404 = function(res) {
    res.writeHead(404, {
      'Content-Type': 'text/html'
    });
    return res.end('<h1>Nothing to see here, move along</h1>');
  };
  server.listen(port);
  io = io.listen(server);
  io.on('clientConnect', function(player) {
    var id;
    for (id in players) {
      player.send({
        type: 'player list',
        playerId: id
      });
    }
    id = player.sessionId;
    players[id] = {
      id: id,
      keys: {}
    };
    ships[id] = new Ship(id);
    player.send({
      type: 'planets',
      planets: planets
    });
    player.send({
      type: 'ships',
      ships: ships
    });
    player.send({
      type: 'connected',
      playerId: id
    });
    return player.broadcast({
      type: 'player joins',
      playerId: id,
      ship: ships[id]
    });
  });
  io.on('clientMessage', function(msg, player) {
    switch (msg.type) {
      case 'key down':
        return processKeyDown(msg.playerId, msg.key);
      case 'key up':
        return processKeyUp(msg.playerId, msg.key);
    }
  });
  io.on('clientDisconnect', function(player) {
    var id;
    id = player.sessionId;
    delete players[id];
    delete ships[id];
    return player.broadcast({
      type: 'player quits',
      playerId: id
    });
  });
  console.log("Server started");
  dirInc = 0.1;
  maxPower = 3;
  minFirepower = 1.3;
  cannonCooldown = 20;
  maxBullets = 5;
  shipSpeed = 0.3;
  frictionDecay = 0.97;
  maxExploFrame = 50;
  map = {
    w: 2000,
    h: 2000
  };
  players = {};
  ships = {};
  bullets = [];
  mines = [];
  planets = [];
  processKeyDown = function(id, key) {
    return players[id].keys[key] = true;
  };
  processKeyUp = function(id, key) {
    players[id].keys[key] = false;
    if (key === 32 || key === 65) {
      if (ships[id].isDead()) {
        ships[id].spawn();
      } else {
        ships[id].fire();
      }
    }
    if (key === 90) {
      return ships[id].dropMine();
    }
  };
  processInputs = function(id) {
    var keys, ship;
    keys = players[id].keys;
    ship = ships[id];
    if (!(ship != null)) {
      return;
    }
    if (keys[37] === true) {
      ship.dir -= dirInc;
      ship.dirtyFields.dir = true;
    }
    if (keys[39] === true) {
      ship.dir += dirInc;
      ship.dirtyFields.dir = true;
    }
    if (keys[38] === true) {
      ship.vel.x += Math.sin(ship.dir) * shipSpeed;
      ship.vel.y -= Math.cos(ship.dir) * shipSpeed;
    }
    if (keys[32] || keys[65]) {
      ship.firePower = Math.min(ship.firePower + 0.1, maxPower);
      return ship.dirtyFields.firePower = true;
    }
  };
  update = function() {
    var diff, id, start;
    start = (new Date).getTime();
    for (id in players) {
      processInputs(id);
    }
    updateBullets();
    updateMines();
    updateShips();
    diff = (new Date).getTime() - start;
    return setTimeout(update, 20 - mod(diff, 20));
  };
  updateShips = function() {
    var changes, id, ship, shipChanges;
    changes = {};
    for (id in ships) {
      ship = ships[id];
      ship.update();
      shipChanges = ship.changes();
      if (!isEmptyObject(shipChanges)) {
        changes[id] = shipChanges;
      }
    }
    if (!isEmptyObject(changes)) {
      return io.broadcast({
        type: 'update',
        update: changes
      });
    }
  };
  updateBullets = function() {
    var b, _i, _len;
    for (_i = 0, _len = bullets.length; _i < _len; _i++) {
      b = bullets[_i];
      b.step();
    }
    if (bullets.length > 0) {
      return io.broadcast({
        type: 'bullets',
        bullets: bullets
      });
    }
  };
  updateMines = function() {
    var m, _i, _len;
    for (_i = 0, _len = mines.length; _i < _len; _i++) {
      m = mines[_i];
      m.update();
    }
    if (mines.length > 0) {
      return io.broadcast({
        type: 'mines',
        mines: mines
      });
    }
  };
  initPlanets = function() {
    var _i, _results;
    _results = [];
    for (_i = 0; _i <= 35; _i++) {
      _results.push(new Planet(Math.random() * 2000, Math.random() * 2000, 50 + Math.random() * 50));
    }
    return _results;
  };
  launch = function() {
    planets = initPlanets();
    return update();
  };
  Ship = (function() {
    function Ship(id) {
      this.id = id;
      this.color = randomColor();
      this.spawn();
    }
    Ship.prototype.spawn = function() {
      this.pos = {
        x: Math.random() * map.w,
        y: Math.random() * map.h
      };
      this.vel = {
        x: 0,
        y: 0
      };
      this.dir = Math.random() * 2 * Math.PI;
      this.firePower = minFirepower;
      this.cannonHeat = 0;
      this.dead = false;
      this.exploFrame = 0;
      this.dirtyFields = {
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
      if (Math.abs(this.pos.x - x) > .05 || Math.abs(this.pos.y - y) > .05) {
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
          ship.explode();
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
    Ship.prototype.dropMine = function() {
      if (this.isDead() || this.isExploding()) {
        return;
      }
      return mines.push(new Mine(this));
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
        this.exploFrame = 0;
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
  info = function(msg) {
    return console.info(msg);
  };
  warn = function(msg) {
    return console.warn(msg);
  };
  log = function(msg) {
    return console.error(msg);
  };
  js = function(path) {
    return path.match(/js$/);
  };
  color = function(rgb, alpha) {
    if (alpha == null) {
      alpha = 1.0;
    }
    return 'rgba(' + rgb + ',' + alpha + ')';
  };
  distance = function(x1, y1, x2, y2) {
    return Math.sqrt((x1 - x2) * (x1 - x2) + (y1 - y2) * (y1 - y2));
  };
  isEmptyObject = function(obj) {
    var p;
    for (p in obj) {
      return false;
    }
    return true;
  };
  mod = function(x, n) {
    if (x > 0) {
      return x % n;
    } else {
      return mod(x + n, n);
    }
  };
  randomColor = function() {
    return Math.round(70 + Math.random() * 150) + ',' + Math.round(70 + Math.random() * 150) + ',' + Math.round(70 + Math.random() * 150);
  };
  launch();
}).call(this);
