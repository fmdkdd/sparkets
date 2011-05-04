class ChangingObject
	constructor: () ->
		@_changes = {}

	watchChanges: (sprops...) ->
		for sprop in sprops
			do (sprop) =>
				@__defineSetter__ sprop, (val) ->
					@change(sprop, val)
				@__defineGetter__ sprop, () ->
					@['_' + sprop]
		return true

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
