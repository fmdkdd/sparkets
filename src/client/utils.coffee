# Console output shortcuts.
log = (msg) ->
	console.log msg

info = (msg) ->
	console.info msg

warn = (msg) ->
	console.warn msg

log = (msg) ->
	console.error msg

# Neat color construction.
color = (rgb, alpha = 1.0) ->
	'rgba(' + rgb + ',' + alpha + ')'

distance = (x1, y1, x2, y2) ->
	Math.sqrt((x1-x2)*(x1-x2) + (y1-y2)*(y1-y2))

# Stupid % operator.
mod = (x, n) ->
	if x > 0 then x%n else mod(x+n, n)
