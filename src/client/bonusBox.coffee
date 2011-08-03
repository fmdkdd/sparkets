class BonusBox

	states:
		'none':
			color: 'grey'
			next: 'rare'
		'rare' :
			color: 'rgb(238,213,13)'
			next: 'regular'
		'regular' :
			color: 'rgb(240,115,15)'
			next: 'plenty'
		'plenty' :
			color : 'rgb(243,52,14)'
			next: 'none'

	bonusSize: 60

	constructor: (@container, @name, @type, @state = 'regular') ->
		
		# Build HTML elements.
		@box = $('<div class="bonusBox"></div>').appendTo(@container)

		@tabs = $('<ul></ul>').appendTo(@box)
		for state, data of @states
			tab = $('<li><span>&nbsp</span></li>').appendTo(@tabs)
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

		# Go to a specific state when a tab is clicked.
		$('li', @box).click (event) =>

			# Find which tab was clicked.
			index = $('li', @box).index(event.target)
			s = 'none'
			s = @states[s].next for [0...index]
			@state = s

			# Update color and label.
			@update()

	update: () ->
		# Change color.
		@box.css('background-color', @states[@state].color)

		# Change label.
		@label.html(@state)

# Exports
window.BonusBox = BonusBox
