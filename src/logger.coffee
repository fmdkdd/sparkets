exports ?= window.logger = {}

## Logger with ANSI colors
# Borrowed from Socket.IO logger

levels =
	error:
		call: console.error
		color: 31
	warn:
		call: console.warn
		color: 33
	info:
		call: console.info
		color: 36
	debug:
		call: console.log
		color: 90
	ship:
		call: console.log
		color: 90
	collisions:
		call: console.log
		color: 90

longestName = 0
for name of levels
	longestName = Math.max(longestName, name.length)

pad = (str) ->
	return str + new Array(longestName - str.length + 1).join(' ');

class Logger
	constructor: (enable = ['error', 'warn', 'info', 'debug']) ->
		@show = {}

		@enable(type) for type in enable

	log: (type, msg) ->
		type = if levels[type]? then type else 'info'
		if @show[type]
			levels[type].call(
				'   \033[' + levels[type].color + 'm' + pad(type) + ' -\033[39m ' + msg)

	error: (msg) -> @log('error', msg)
	warn: (msg) -> @log('warn', msg)
	info: (msg) -> @log('info', msg)
	debug: (msg) -> @log('debug', msg)

	enable: (type) -> @show[type] = yes
	disable: (type) -> @show[type] = no

# For new logger instances.
exports.create = Logger.constructor

# The shared logger.
singleton = exports.static = new Logger()

exports.set = (enable) ->
	singleton.show = {}
	singleton.enable(type) for type in enable
	return singleton