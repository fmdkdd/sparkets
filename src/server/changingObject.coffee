class ChangingObject
	constructor: () ->
		@_changes = {}

	watchChanges: (sprop) ->
		@__defineSetter__ sprop, (val) ->
			@change(sprop, val)
		@__defineGetter__ sprop, () ->
			@['_' + sprop]

	change: (sprop, val) ->
		@['_' + sprop] = val
		@_changes[sprop] = val

	changed: (sprop) ->
		@_changes[sprop] = @['_' + sprop]

	changes: () ->
		@_changes

	resetChanges: () ->
		@_changes = {}

exports.ChangingObject = ChangingObject
