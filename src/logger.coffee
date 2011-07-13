exports ?= window

## Logger with ANSI colors
# Borrowed from Socket.IO logger

levels =
	error:
		call: console.error
		color: 31
		show: yes
	warn:
		call: console.warn
		color: 33
		show: yes
	info:
		call: console.info
		color: 36
		show: yes
	debug:
		call: console.log
		color: 90
		show: yes
	ship:
		call: console.log
		color: 90
		show: no
	collisions:
		call: console.log
		color: 90
		show: no

longestName = 0
for name of levels
	longestName = Math.max(longestName, name.length)

pad = (str) ->
	return str + new Array(longestName - str.length + 1).join(' ');

exports.log = (type, msg) ->
	type = if levels[type]? then type else 'info'
	if levels[type].show
		levels[type].call(
			'   \033[' + levels[type].color + 'm' + pad(type) + ' -\033[39m ' + msg)

exports.error = (msg) -> exports.log('error', msg)
exports.warn = (msg) -> exports.log('warn', msg)
exports.info = (msg) -> exports.log('info', msg)
exports.debug = (msg) -> exports.log('debug', msg)

exports.enable = (type) -> levels[type].show = yes
exports.disable = (type) -> levels[type].show = no
