class BonusBox
	constructor: (@container, @name, @type, @state = 'regular') ->
		
		@states =
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

		# Build.
		@canvas = $('<canvas class="bonusBox" width="75" height="100"></canvas><span>&nbsp</span>').appendTo(@container)
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
		@ctxt.font = '1.2em Arial'
		@ctxt.fillText(@state, 75/2-@ctxt.measureText(@state).width/2, 90)
		

# Exports
window.BonusBox = BonusBox
