(function() {
  var Bullet, Planet, Ship, bullets, cannonCooldown, dirInc, distance, frictionDecay, fs, http, info, initPlanets, io, log, map, maxBullets, maxExploFrame, maxPower, minFirepower, mod, planets, players, port, processInputs, processKeyDown, processKeyUp, randomColor, send404, server, shipSpeed, ships, update, updateBullets, updateShips, url, warn;
  var __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; };
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
      case '/cplient.js':
      case '/ship.js':
      case '/bullet.js':
      case '/planet.js':
      case '/utils.js':
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
        type: 'player list'
      }, {
        playerId: id
      });
    }
    id = player.sessionId;
    players[id] = {};
    players[id].id = id;
    players[id].keys = {};
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
      playerId: id
    });
  });
  io.on('clientMessage', function(msg, player) {
    switch (msg.type) {
      case 'key down':
        return alert('x');
      case 'key up':
        return alert('y');
    }
  });
  io.on('clientDisconnect', function(player) {
    var id;
    id = player.sessionId;
    delete players[id];
    delete ships[id];
    return player.broadcast({
      type: 'player quits'
    }, {
      playerId: id
    });
  });
  console.log("Server started");
  processKeyDown = function(id, key) {
    return players[id].keys[key] = true;
  };
  processKeyUp = function(id, key) {
    players[id].keys[key] = false;
    if (key === 32) {
      return ships[id].fire();
    }
  };
  processInputs = function(id) {
    var keys, ship;
    keys = players[id].keys;
    ship = ships[id];
    if (!(ship != null) || ship.isDead) {
      return;
    }
    if (keys[37] === true) {
      ship.dir -= dirInc;
    }
    if (keys[39] === true) {
      ship.dir += dirInc;
    }
    if (keys[38] === true) {
      ship.vel.x += Math.sin(ship.dir) * shipSpeed;
      ship.vel.y -= Math.cos(ship.dir) * shipSpeed;
    }
    if (keys[32] === true) {
      return ship.firePower = Math.min(ship.firePower + 0.1, maxPower);
    }
  };
  update = function() {
    var diff, id, start;
    start = (new Date).getTime();
    for (id in players) {
      processInputs(id);
    }
    updateBullets();
    updateShips();
    diff = (new Date).getTime() - start;
    return setTimeout(update, 20 - mod(diff, 20));
  };
  updateShips = function() {
    var s, _i, _len;
    for (_i = 0, _len = ships.length; _i < _len; _i++) {
      s = ships[_i];
      s.update();
    }
    return io.broadcast({
      type: 'ships'
    }, {
      ships: ships
    });
  };
  updateBullets = function() {
    var b, _i, _len;
    for (_i = 0, _len = bullets.length; _i < _len; _i++) {
      b = bullets[_i];
      b.step();
    }
    return io.broadcast({
      type: 'bullets'
    }, {
      bullets: bullets
    });
  };
  initPlanets = function() {
    var planets, _i;
    planets = [];
    for (_i = 0; _i <= 35; _i++) {
      planets.push(new Planet(Math.random() * 2000, Math.random() * 2000, 50 + Math.random() * 50));
    }
    return planets;
  };
  Ship = (function() {
    function Ship(id) {
      this.id = id;
      this.pos = {
        x: x,
        y: y
      };
      this.vel = {
        x: 0,
        y: 0
      };
      this.dir = Math.random() * 2 * Math.PI;
      this.color = randomColor();
      this.firePower = minFirepower;
      this.cannonHeat = 0;
      this.dead = false;
    }
    Ship.prototype.move = function() {
      this.pos.x += this.vel.x;
      this.pos.y += this.vel.y;
      this.pos.x = this.pos.x < 0 ? map.w : this.pos.x;
      this.pos.x = this.pos.x > map.w ? 0 : this.pos.x;
      this.pos.y = this.pos.y < 0 ? map.h : this.pos.y;
      this.pos.y = this.pos.y > map.h ? 0 : this.pos.y;
      this.vel.x *= frictionDecay;
      return this.vel.y *= frictionDecay;
    };
    Ship.prototype.collides = function() {
      return this.collidesWithOtherShip || this.collidesWithPlanet() || this.collidesWithBullet();
    };
    Ship.prototype.collidesWithOtherShip = function() {
      var s, x, y, _i, _len;
      x = this.pos.x;
      y = this.pos.y;
      for (_i = 0, _len = ships.length; _i < _len; _i++) {
        s = ships[_i];
        if (this !== s && Math.abs(x - ship.pos.x) < 10 && Math.abs(y - ship.pos.y) < 10) {
          return true;
        }
      }
      return false;
    };
    Ship.prototype.collidesWithPlanet = function() {
      var x, y;
      x = this.pos.x;
      y = this.pos.y;
      return planets.some(__bind(function(p) {
        var px, py;
        px = p.pos.x(py = p.pos.y);
        return Math.sqrt((px - x) * (px - x) + (py - y) * (py - y)) < p.force;
      }, this));
    };
    Ship.prototype.collidesWithBullet = function() {
      var b, x, y, _i, _len;
      x = this.pos.x;
      y = this.pos.y;
      for (_i = 0, _len = bullets.length; _i < _len; _i++) {
        b = bullets[_i];
        if (!b.dead && Math.abs(x - b.pos.x) < 10 && Math.abs(y - b.pos.y) < 10) {
          b.dead = true;
          return true;
        }
      }
      return false;
    };
    Ship.prototype.isDead = function() {
      return this.dead || (this.exploBits != null);
      (function() {});
      if (this.dead) {
        return;
      }
      if (this.exploBits != null) {
        return this.updateExplosion();
      } else {
        --this.cannonHeat;
        this.move();
        if (this.collides()) {
          return this.explode;
        }
      }
    };
    Ship.prototype.fire = function() {
      if (this.isDead() || this.cannonHeat > 0) {
        return;
      }
      bullets.push(new Bullet(this));
      if (bullets.length > maxBullets) {
        bullets.shift;
      }
      this.firePower = minFirepower;
      return this.cannonHeat = cannonCooldown;
    };
    Ship.prototype.explode = function() {
      var vel, _i, _results;
      this.exploBits = [];
      this.exploFrame = 0;
      vel = Math.max(this.vel.x, this.vel.y);
      _results = [];
      for (_i = 0; _i <= 200; _i++) {
        _results.push(this.exploBits.push({
          x: this.pos.x
        }, {
          y: this.pos.y,
          vx: .5 * vel * (2 * Math.random()(-1)),
          vy: .5 * vel * (2 * Math.random()(-1))
        }));
      }
      return _results;
    };
    Ship.prototype.updateExplosion = function() {
      var b, _i, _len, _ref;
      _ref = this.exploBits;
      for (_i = 0, _len = _ref.length; _i < _len; _i++) {
        b = _ref[_i];
        b.x += b.vx + (2 * Math.random()(-1)) / 1.5;
        b.y += b.vy + (2 * Math.random()(-1)) / 1.5;
      }
      ++this.exploFrame;
      if (this.exploFrame > maxExploFrame) {
        this.dead = true;
        delete ships[this.id];
        delete this.exploBits;
        return delete this.exploFrame;
      }
    };
    return Ship;
  })();
  Bullet = (function() {
    function Bullet(owner) {
      this.owner = owner;
      this.pos = {
        x: this.owner.pos.x({
          y: this.owner.pos.y
        })
      };
      this.accel = {
        x: this.owner.vel.x + 10 * this.power * Math.sin(owner.dir)({
          y: this.owner.vel.y + -10 * this.power * Math.cos(owner.dir)
        })
      };
      this.power = this.owner.firePower;
      this.dead = false;
      this.color = owner.color;
      this.points = [[this.pos.x + 10 * Math.sin(owner.dir), this.pos.y - 10 * Math.cos(owner.dir)]];
    }
    Bullet.prototype.step = function() {
      var ax, ay, d, d2, nx, ny, p, x, y, _i, _len;
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
      nx = x + ax;
      ny = y + ay;
      this.points.push([nx, ny]);
      this.pos.x = nx;
      this.pos.y = ny;
      this.accel.x = ax;
      this.accel.y = ay;
      this.pos.x = this.pos.x < 0 ? map.w : this.pos.x;
      this.pos.x = this.pos.x > map.w ? 0 : this.pos.x;
      this.pos.y = this.pos.y < 0 ? map.h : this.pos.y;
      this.pos.y = this.pos.y > map.h ? 0 : this.pos.y;
      if (this.collides()) {
        return this.dead = true;
      }
    };
    Bullet.prototype.collides = function() {
      return this.collidesWithPlanet();
    };
    Bullet.prototype.collidesWithPlanet = function() {
      var x, y;
      x = this.pos.x;
      y = this.pos.y;
      return planets.some(function(p) {
        var px, py;
        px = p.pos.x(py = p.pos.y);
        return Math.sqrt((px - x) * (px - x) + (py - y) * (py - y)) < p.force;
      });
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
  info = function(msg) {
    return console.info(msg);
  };
  warn = function(msg) {
    return console.warn(msg);
  };
  log = function(msg) {
    return console.error(msg);
  };
  mod = function(x, n) {
    if (x > 0) {
      return x % n;
    } else {
      return n + (x % n);
    }
  };
  distance = function(x1, y1, x2, y2) {
    return Math.sqrt((x1 - x2) * (x1 - x2) + (y1 - y2) * (y1 - y2));
  };
  randomColor = function() {
    return Math.round(70 + Math.random() * 150) + ',' + Math.round(70 + Math.random() * 150) + ',' + Math.round(70 + Math.random() * 150);
  };
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
  planets = initPlanets();
  update();
}).call(this);
