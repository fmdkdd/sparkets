class Tooltip
	constructor: (@target, @text) ->

		@tooltip = null

		@target.mouseover (event) =>
			@tooltip = $('<div class="tooltip">'+@text+'</div>').appendTo('body')

		@target.mousemove (event) =>
			return if not @tooltip?

			@tooltip.css('left', event.pageX)
			@tooltip.css('top', @target.offset().top + @target.height() + 10)	

		@target.mouseout (event) =>
			@tooltip.remove()
			@tooltip = null

# Exports
window.Tooltip = Tooltip
