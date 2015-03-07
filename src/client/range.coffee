class Range
  constructor: (@container, @name, @min, @max, @step, @default, @suffix = '') ->

    # Build html elements.
    @container = $('<span class="range"></span>').appendTo(@container)

    @range = $('<input type="range"/>').appendTo(@container)
    @range.attr('name', @name)
    @range.attr('min', @min)
    @range.attr('max', @max)
    @range.attr('step', @step)
    @range.attr('value', @default)

    @range.after('<span></span>')
    @update()

    @range.change (event) =>
      @update()

  value: () ->
    @range.attr('value')

  update: () ->
    @range.find('+ span').html(utils.prettyNumber(@value()) + @suffix)

# Exports
window.Range = Range
