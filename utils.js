(function() {
  var color, info, log, mod, warn;
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
