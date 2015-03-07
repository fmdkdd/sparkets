var util = require('util');
var fs = require('fs');
var spawn = require('child_process').spawn;

var files = process.argv.slice(2);
var make, child;

watchFiles(files, restart);
run();

function run() {
  make = spawn('make', ['test']);
  make.stdout.pipe(process.stdout);
  make.stderr.pipe(process.stderr);

  make.on('exit', function(code) {
    if (code !== 0) {
      console.log('make exited with code ' + code);
    } else {
      child = spawn('node', ['build/server/run.js']);

      child.stdout.pipe(process.stdout);
      child.stderr.pipe(process.stderr);
    }
  });
}

function restart() {
  if (make) make.kill();
  if (child) child.kill();
  run();
}

function watchFiles(files, callback) {
  var config = { persistent: true, interval: 2 };
  files.forEach(function (file) {
    fs.watchFile(file, config, function (curr, prev) {
      if ((curr.mtime + '') !== (prev.mtime + '')) {
        if (callback) callback();
      }
    });
  });
}
