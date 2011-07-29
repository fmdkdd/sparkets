class BonusBox
	constructor: (@container, @name, @type, @state = 'regular') ->
		
		@states =
			'none':
				color: 'lightgrey'
				next: 'rare'
			'rare' :
				color: 'red'
				next: 'regular'
			'regular' :
				color: 'orange'
				next: 'plenty'
			'plenty' :
				color : 'yellow'
				next: 'none'

		# Build.
		@canvas = $('<canvas class="bonusBox" width="75" height="100"></canvas>').appendTo(@container)
		@ctxt = @canvas[0].getContext('2d')

		# Paste the bonus sprite onto the canvas.
		@drawBonus()

		# Paste the frame onto the canvas.
		@drawFrame()		

		@canvas.click (event) =>
			@state = @states[@state].next
			@drawFrame()

	drawBonus: () ->
		# Paste the bonus sprite onto the canvas.
		@sprite = window.spriteManager.get(@type, 50, 50, 'black')
		@ctxt.drawImage(@sprite, @canvas[0].width/2-@sprite.width/2, 75/2-@sprite.height/2)

	drawFrame: () ->
		# paste the frame onto the canvas.
		@frame = window.spriteManager.get('frame', 75, 100, @states[@state].color)
		@ctxt.drawImage(@frame, 0, 0)

		# Draw current state name.
		@ctxt.fillStyle = 'white'
		@ctxt.fillText(@state, 75/2-@ctxt.measureText(@state).width/2, 90)
		

# Exports
window.BonusBox = BonusBox
