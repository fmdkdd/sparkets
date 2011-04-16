(function() {
  var Bullet, Planet, Ship, bullets, centerView, color, ctxt, drawInfinity, id, inView, info, init, interp_factor, interpolate, lastUpdate, log, map, maxExploFrame, maxPower, mod, onConnect, onDisconnect, onMessage, planetColor, planets, port, ready, redraw, screen, serverShips, ships, update, view, warn;
  var __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; };
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
  port = 12345;
  ctxt = null;
  screen = {
    w: 0,
    h: 0
  };
  map = {
    w: 2000,
    h: 2000
  };
  view = {
    x: 0,
    y: 0
  };
  planetColor = '127, 157, 185';
  interp_factor = .03;
  lastUpdate = 0;
  maxPower = 3;
  maxExploFrame = 50;
  id = null;
  ships = {};
  serverShips = {};
  planets = [];
  bullets = [];
  init = function() {
    var socket;
    socket = new io.Socket(null, {
      port: port
    });
    socket.connect();
    socket.on('message', onMessage);
    socket.on('connect', onConnect);
    socket.on('disconnect', onDisconnect);
    ctxt = document.getElementById('canvas').getContext('2d');
    $(window).resize(__bind(function(event) {
      screen.w = document.getElementById('canvas').width = window.innerWidth;
      screen.h = document.getElementById('canvas').height = window.innerHeight;
      return centerView();
    }, this));
    return $(window).resize();
  };
  $(document).ready(__bind(function() {
    return init();
  }, this));
  ready = function() {
    $(document).keydown(__bind(function(event) {
      return socket.send({
        type: 'key down',
        playerId: id,
        key: event.keyCode
      });
    }, this));
    $(document).keyup(__bind(function(event) {
      return socket.send({
        type: 'key up',
        playerId: id,
        key: event.keyCode
      });
    }, this));
    return update();
  };
  interpolate = function(time) {
    var ddir, dx, dy, id, s, shadow, ship, _results;
    if (time * interp_factor > 1) {
      info(time);
    }
    _results = [];
    for (id in serverShips) {
      s = serverShips[id];
      ship = ships[id];
      shadow = serverShips[id];
      if (!(ship != null)) {
        ships[id] = shadow;
        continue;
      }
      dx = shadow.pos.x - ship.pos.x;
      if (Math.abs(dx < .1 && Math.abs(dx > 100))) {
        ship.pos.x = shadow.pos.x;
      } else {
        ship.pos.x += dx * time * interp_factor;
      }
      dy = shadow.pos.y - ship.pos.y;
      if (Math.abs(dy < .1 && Math.abs(dy > 100))) {
        ship.pos.y = shadow.pos.y;
      } else {
        ship.pos.y += dy * time * interp_factor;
      }
      ddir = shadow.dir - ship.dir;
      if (Math.abs(ddir < .01)) {
        ship.dir = shadow.dir;
      } else {
        ship.dir += ddir * time * interp_factor;
      }
      ship.vel = shadow.vel;
      ship.dir = shadow.dir;
      ship.color = shadow.color;
      ship.firePower = shadow.firePower;
      ship.dead = shadow.dead;
      ship.exploBits = shadow.exploBits;
      _results.push(ship.exploFrame = shadow.exploFrame);
    }
    return _results;
  };
  update = function() {
    var diff, start;
    start = (new Date).getTime();
    interpolate((new Date).getTime() - lastUpdate);
    centerView();
    redraw(ctxt);
    diff = (new Date).getTime() - start;
    return setTimeout(update, 20 - mod(diff, 20));
  };
  inView = function(x, y) {
    return x >= view.x && x <= view.x + screen.w && y >= view.y && y <= view.y + screen.h;
  };
  redraw = function(ctxt) {
    var b, i, len, p, s, _i, _j, _len, _len2, _ref;
    ctxt.clearRect(0, 0, screen.w, screen.h);
    ctxt.lineWidth = 4;
    ctxt.lineJoin = 'round';
    len = bullets.length;
    for (b in bullets) {
      i = bullets[b];
      b.draw(ctxt, (i + 1) / len);
    }
    for (_i = 0, _len = planets.length; _i < _len; _i++) {
      p = planets[_i];
      p.draw(ctxt);
    }
    for (_j = 0, _len2 = ships.length; _j < _len2; _j++) {
      s = ships[_j];
      s.draw(ctxt);
      if (!((_ref = ships[id]) != null ? _ref.isDead() : void 0)) {
        drawRadar(ctxt);
      }
    }
    return drawInfinity(ctxt);
  };
  centerView = function() {
    if (ships[id] != null) {
      view.x = ships[id].pos.x - screen.w / 2;
      return view.y = ships[id].pos.y - screen.h / 2;
    }
  };
  ({
    drawRadar: function(ctxt) {
      var d, dx, dy, i, rx, ry, s, _len, _results;
      _results = [];
      for (s = 0, _len = ships.length; s < _len; s++) {
        i = ships[s];
        _results.push(i !== id ? (dx = ships[s].pos.x - ships[id].pos.x, dy = ships[s].pos.y - ships[id].pos.y, d = Math.sqrt(dx * dx + dy * dy), rx = dx / d * 50, ry = dy / d * 50, ctxt.strokeStyle = color(planetColor), ctxt.beginPath(), ctxt.arc(screen.w / 2 + rx, screen.h / 2 + ry, 2, 0, 2 * Math.PI, false), ctxt.stroke()) : void 0);
      }
      return _results;
    }
  });
  drawInfinity = function(ctxt) {
    var b, bottom, i, j, left, p, right, s, top, visibility, _i, _j, _len, _len2, _results;
    left = view.x < 0;
    right = view.x > map.w - screen.w;
    top = view.y < 0;
    bottom = view.y > map.h - screen.h;
    visibility = [[left && top, top, right && top], [left, false, right], [left && bottom, bottom, right && bottom]];
    for (i = 0; i <= 3; i++) {
      for (j = 0; j <= 3; j++) {
        if (visibility[i][j] === true) {
          for (_i = 0, _len = planets.length; _i < _len; _i++) {
            p = planets[_i];
            p.draw(ctxt, {
              x: (j - 1) * map.w,
              y: (i - 1) * map.h
            });
          }
        }
      }
    }
    for (i = 0; i <= 3; i++) {
      for (j = 0; j <= 3; j++) {
        if (visibility[i][j] === true) {
          for (_j = 0, _len2 = ships.length; _j < _len2; _j++) {
            s = ships[_j];
            s.draw(ctxt, {
              x: (j - 1) * map.w,
              y: (i - 1) * map.h
            });
          }
        }
      }
    }
    _results = [];
    for (i = 0; i <= 3; i++) {
      _results.push((function() {
        var _results;
        _results = [];
        for (j = 0; j <= 3; j++) {
          _results.push((function() {
            var _i, _len, _results;
            if (visibility[i][j] === true) {
              _results = [];
              for (_i = 0, _len = bullets.length; _i < _len; _i++) {
                b = bullets[_i];
                _results.push(b.draw(ctxt, 255, {
                  x: (j - 1) * map.w,
                  y: (i - 1) * map.h
                }));
              }
              return _results;
            }
          })());
        }
        return _results;
      })());
    }
    return _results;
  };
  onConnect = function() {
    return info("Connected to server");
  };
  onDisconnect = function() {
    return info("Aaargh! disconnected!");
  };
  onMessage = function(msg) {
    var b, p, s, _i, _j, _k, _l, _len, _len2, _len3, _len4, _ref, _ref2, _ref3, _results, _results2;
    switch (msg.type) {
      case 'bullets':
        bullets = [];
        _ref = msg.bullets;
        _results = [];
        for (_i = 0, _len = _ref.length; _i < _len; _i++) {
          b = _ref[_i];
          _results.push(bullets.push(new Bullet(b)));
        }
        return _results;
        break;
      case 'ships':
        serverShips = {};
        _ref2 = msg.ships;
        for (_j = 0, _len2 = _ref2.length; _j < _len2; _j++) {
          s = _ref2[_j];
          serverShips[s] = new Ship(s);
        }
        lastUpdate = (new Date).getTime();
        for (_k = 0, _len3 = ships.length; _k < _len3; _k++) {
          s = ships[_k];
          if (!(serverShips[s] != null)) {
            delete s;
          }
        }
        return ships = {};
      case 'planets':
        planets = [];
        _ref3 = msg.planets;
        _results2 = [];
        for (_l = 0, _len4 = _ref3.length; _l < _len4; _l++) {
          p = _ref3[_l];
          _results2.push(planets.push(new Planet(p)));
        }
        return _results2;
        break;
      case 'connected':
        id = msg.playerId;
        return ready();
      case 'player joins':
        return console.info('player joins');
      case 'player dies':
        return console.info('player dies');
      case 'player quits':
        return console.info('player quits');
    }
  };
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
  color = function(rgb, alpha) {
    if (!(alpha != null)) {
      return 'rgb(' + rgb + ')';
    } else {
      return 'rgba(' + rgb + ',' + alpha + ')';
    }
  };
  mod = function(x, n) {
    if (x > 0) {
      return x % n;
    } else {
      return n + (x % n);
    }
  };
}).call(this);
