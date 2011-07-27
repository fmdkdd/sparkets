class ChangingObject
	constructor: () ->
		@_changes = {}
		@_watched = {}

	watchChanges: (sprop) ->
		if @[sprop]?
			@['_' + sprop] = @[sprop]
			delete @[sprop]

		@_watched[sprop] = yes
		@__defineSetter__ sprop, (val) ->
			@change(sprop, val)
		@__defineGetter__ sprop, () ->
			@['_' + sprop]
		true

	unwatchChanges: (sprop) ->
		if @_watched[sprop]?
			delete @_watched[sprop]
			delete @[sprop]
			@[sprop] = @['_' + sprop]
			delete @['_' + sprop]
		true

	watched: () ->
		watch = {}
		for prop, val of @_watched
			watch[prop] = @[prop]

		return watch

	change: (sprop, val) ->
		@['_' + sprop] = val
		@_changes[sprop] = val

	changed: (sprop) ->
		if @_watched[sprop]?
			@_changes[sprop] = @['_' + sprop]

	changes: () ->
		@_changes

	resetChanges: () ->
		@_changes = {}

exports.ChangingObject = ChangingObject
