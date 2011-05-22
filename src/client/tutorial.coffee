class Tutorial
	constructor: () ->

		@fadeDuration = 1000
		@expositionDuration = 10000

		@current = 0
		@slides = ['/tutorialMove.svg', '/tutorialShoot.svg']

		@load()

	load: () ->
		for i, s of @slides
			$('body').append('<img id="slide' + i + '" class="slide" src="' + s + '"/>')
		$('.slide').hide()

	start: () ->
		@fadeIn()

	fadeIn: () ->
		info 'in '+@current
		# Fade-in the current slide
		if @current < @slides.length
			$('#slide' + @current).fadeIn(@fadeDuration, () => @pause())

	pause: () ->
		info 'pause '+@current
		setTimeout((() => @fadeOut()), @expositionDuration)

	fadeOut: () ->
		info 'out '+@current
		# Fade-out the current slide.
		$('#slide' + @current).fadeOut(@fadeDuration, () => @fadeIn())
		++@current
