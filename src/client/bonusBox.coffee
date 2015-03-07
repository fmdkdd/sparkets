class BonusBox

  states:
    'none':
      color: 'grey'
      next: 'rare'
    'rare' :
      color: 'hsl(53, 90%, 49%)'
      next: 'regular'
    'regular' :
      color: 'hsl(27, 88%, 50%)'
      next: 'plenty'
    'plenty' :
      color : 'hsl(10, 91%, 50%)'
      next: 'none'

  bonusSize: 60

  constructor: (@container, @name, @type, @state = 'regular') ->

    # Build HTML elements.
    @box = $('<div class="bonusBox"></div>').appendTo(@container)

    @tabs = $('<ul></ul>').appendTo(@box)
    for state, data of @states
      tab = $('<li id="'+state+'"><span>&nbsp</span></li>').appendTo(@tabs)
      tab.css('background-color', @states[state].color)
      tab.width('25%');

    @content = $('<div></div>').appendTo(@box)

    @canvas = $('<canvas></canvas>')
    @canvas.attr('width', @bonusSize)
    @canvas.attr('height', @bonusSize)
    @content.append(@canvas)

    @label = $('<span class="label"></span>').appendTo(@content)

    # Paste the bonus sprite onto the canvas.
    @sprite = window.spriteManager.get(@type, @bonusSize, @bonusSize, 'black')
    @ctxt = @canvas[0].getContext('2d')
    @ctxt.drawImage(@sprite, 0, 0)

    # Setup color and label.
    @update()

    # Go to next state when the box is clicked.
    $(@content).click (event) =>
      @state = @states[@state].next

      # Update color and label.
      @update()

    # Go to a specific state when its tab is clicked.
    $('li', @box).click (event) =>

      # Find which tab was clicked.
      index = $('li', @box).index(event.target)
      if index >= 0
        s = 'none'
        s = @states[s].next for [0...index]
        @state = s

        # Update color and label.
        @update()

  update: () ->
    # Change color.
    @label.css('color', @states[@state].color)

    # Change label.
    @label.html(@state)

# Exports
window.BonusBox = BonusBox
