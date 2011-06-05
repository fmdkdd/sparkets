class Tutorial
	constructor: () ->

		@startDelay = 2000
		@fadeDuration = 1000
		@expositionDuration = 10000

		@current = 0
		@slides = ['/img/tutorialMove.svg', '/img/tutorialShoot.svg']

		@load()

		setTimeout((() => @start()), @startDelay)

	load: () ->
		for i, s of @slides
			$('body').append('<img id="slide' + i + '" class="slide" src="' + s + '"/>')
		$('.slide').hide()

	start: () ->
		@fadeIn()

	fadeIn: () ->
		# Fade-in the current slide
		if @current < @slides.length
			$('#slide' + @current).fadeIn(@fadeDuration, () => @pause())
		# Mark the tutorial as passed.
		else
			localStorage['spacewar.tutorial'] = true


	pause: () ->
		setTimeout((() => @fadeOut()), @expositionDuration)

	fadeOut: () ->
		# Fade-out the current slide.
		$('#slide' + @current).fadeOut(@fadeDuration, () => @fadeIn())
		++@current
