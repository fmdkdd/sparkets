class Range
	constructor: (@container, @label, @name, @min, @max, @step, @default) ->

		# Build html elements.
		@container.append('<label for="' + @name + '">' + @label + '</label>')
		@range = $('<input type="range" name="' + @name + '" min="' + @min + '" max="' + @max + '" step="' + @step + '" value="' + @default + '"/>').appendTo(@container)

		# Tooltip to indicate current value for range input.
		# Created at mouse down and detached on mouse up, the tooltip
		# follows the mouse pointer on mouse move.

		@tooltip = null

		@range.mousedown (event) =>
			return if event.which isnt 1

			# With enough clicking around you can avoid a mouse up
			# event. Clear any previously created tooltip to avoid
			# duplicates.
			@tooltip.detach() if @tooltip?

			@tooltip = $('<span class="tooltip"></span>').appendTo('body')
			@tooltip.css('position', 'absolute')
			@tooltip.css('top', @range.offset().top - @range.height())
			@tooltip.css('left', event.pageX)

			@updateTooltip()

		# Update tooltip value and follow pointer.
		@range.mousemove (event) =>
			return if event.which isnt 1
			return if not @tooltip?

			# Constrain to input element width.
			xOff = event.pageX
			left = @range.offset().left
			xOff = left if xOff < left
			right = left + @range.innerWidth()
			xOff = right if xOff > right

			@tooltip.css('left', xOff)

			@updateTooltip()

		# Delete tooltip.
		@range.mouseup (event) =>
			return if event.which isnt 1
			return if not @tooltip?

			@tooltip.detach()
			@tooltip = null

	updateTooltip: () ->
		str = window.utils.prettyNumber(@range.val())

		# Delay tooltip value update after the value has been updated
		# in the browser. Otherwise, clicking away from the slider
		# cursor will move the cursor to the mouse but @.value won't
		# be updated.
		setTimeout( (() => @tooltip.html(str) ), 1)

# Exports
window.Range = Range
