class ChangingObject
	constructor: () ->
		@_changes = {}
		@_watched = {}

	watchChanges: (sprops...) ->
		for sprop in sprops
			@_watched[sprop] = yes
			do (sprop) =>
				@__defineSetter__ sprop, (val) ->
					@change(sprop, val)
				@__defineGetter__ sprop, () ->
					@['_' + sprop]
		return true

	watched: () ->
		watch = {}
		for prop, val of @_watched
			watch[prop] = @[prop]

		return watch

	change: (sprop, val) ->
		@['_' + sprop] = val
		@_changes[sprop] = val

	changed: (sprop) ->
		@_changes[sprop] = @['_' + sprop]

	changes: () ->
		@_changes

	resetChanges: () ->
		@_changes = {}

	collidedWith: (types...) ->
		@collisions.some ({type}) ->
			types.some (t) ->
				type is t

exports.ChangingObject = ChangingObject
