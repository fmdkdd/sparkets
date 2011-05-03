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

# Stupid % operator.
mod = (x, n) ->
	if x > 0 then x%n else mod(x+n, n)
