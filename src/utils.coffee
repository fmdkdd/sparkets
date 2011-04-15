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
color = (rgb, alpha) ->
	if not alpha?
		return 'rgb(' + rgb + ')'
	else
		return 'rgba(' + rgb + ',' + alpha + ')'

# Stupid % operator.
mod = (x, n) ->
	if x > 0 then return x%n else return n+(x%n)
