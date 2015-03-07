class SelectionBox
  constructor: (@container, @name, @items, @default) ->

    # Build table.
    @table = $('<table class="selectionBox"><tr></tr></table>').appendTo(@container)

    # Add buttons.
    html = ''
    for i in [0...@items.length]
      html += '<th><button ' + (if i is @default then 'class="selected"' else '') + ' value="' + @items[i] + '">' + utils.capitalize(@items[i]) + '</button></th>'
    @table.find('tr').append(html)

    # Bind a click event to the buttons.
    @table.find('button').click (event) ->
      event.preventDefault()
      $(@).parent().parent().find('button.selected').removeClass('selected')
      $(@).addClass('selected')

  value: () ->
    @table.find('button.selected').val()

# Exports
window.SelectionBox = SelectionBox
