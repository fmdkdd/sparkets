(function() {
  var bullets, centerView, drawInfinity, init, interp_factor, interpolate, lastUpdate, map, maxExploFrame, maxPower, onConnect, onDisconnect, onMessage, planetColor, planets, port, ready, redraw, screen, serverShips, ships, update, view;
  var __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; };
  port = 12345;
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
  ships = {};
  serverShips = {};
  planets = [];
  bullets = [];
  init = function() {
    var ctxt, socket;
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
  ready = function() {
    document.onkeydown(__bind(function(event) {
      return socket.send({
        type: 'key down',
        playerId: id,
        key: event.keyCode
      });
    }, this));
    document.onkeyup(__bind(function(event) {
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
  ({
    inView: function(x, y) {
      return x >= view.x && x <= view.x + screen.w && y >= view.y && y <= view.y + screen.h;
    }
  });
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
    var b, id, p, s, _i, _j, _k, _l, _len, _len2, _len3, _len4, _ref, _ref2, _ref3, _results, _results2;
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
}).call(this);
