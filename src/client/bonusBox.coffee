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

	width: 75
	height: 100
	headerHeight: 10

	constructor: (@container, @name, @type, @state = 'regular') ->
		
		# Build the canvas.
		@canvas = document.createElement('canvas')
		@canvas.width = @width
		@canvas.height = @height + @headerHeight
		@container.append(@canvas)
		@container.append('<span>&nbsp</span>') # TODO: replace spacing between bonuses with CSS rule.
		@ctxt = @canvas.getContext('2d')

		# Build the canvas header.
		@canvasHeader = document.createElement('canvas')
		@canvasHeader.width = @width
		@canvasHeader.height = @headerHeight
		headerCtxt = @canvasHeader.getContext('2d')

		for id, data of @states
			headerCtxt.fillStyle = data.color
			headerCtxt.fillRect(0, 0, @width/4, @headerHeight)
			headerCtxt.translate(@width/4, 0)

		# Paste the bonus sprite onto the canvas.
		@drawBonus()

		# Paste the frame onto the canvas.
		@drawFrame()		

		$(@canvas).click (event) =>
			@state = @states[@state].next
			@drawFrame()

	drawBonus: () ->

		# Paste the bonus sprite onto the canvas.
		@sprite = window.spriteManager.get(@type, 50, 50, 'black')
		@ctxt.drawImage(@sprite, @width/2-@sprite.width/2, 75/2-@sprite.height/2+@headerHeight)

	drawFrame: () ->
	
		# Paste the canvas header.
		@ctxt.drawImage(@canvasHeader, 0, 0)

		# Paste the frame onto the canvas.
		@frame = window.spriteManager.get('frame', @width, @height, @states[@state].color)
		@ctxt.drawImage(@frame, 0, @headerHeight)

		# Draw current state name.
		@ctxt.fillStyle = 'white'
		@ctxt.font = '1.2em Arial'
		@ctxt.fillText(@state, @width/2-@ctxt.measureText(@state).width/2, @height+@headerHeight-10)
		
# Exports
window.BonusBox = BonusBox
