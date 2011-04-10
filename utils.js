// Console output shortcuts.
function log(msg) { console.log(msg); }
function info(msg) { console.info(msg); }
function warn(msg) { console.warn(msg); }
function error(msg) { console.error(msg); }

// Neat color construction
function color(rgb, alpha) {
	if (alpha === undefined)
		return 'rgb(' + rgb + ')';
	else
		return 'rgba(' + rgb + ',' + alpha + ')';
}

// Stupid % operator
function mod(x, n) {
	return x > 0 ? x%n : n+(x%n);
}