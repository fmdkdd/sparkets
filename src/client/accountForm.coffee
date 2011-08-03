class AccountForm
	constructor: () ->

		window.accountForm = @

		# Build the HTML elements.
		@popup = $('<section id="accountForm"></section>').appendTo('body')

		@cache = $('<div id="cache"></div>').appendTo('body')

		@table = $('<table><tr><th>Log in</th><th>Sign up</th></tr><tr><td></td><td></td></tr></table>').appendTo(@popup)
		@formLogin = $('<form></form>').appendTo('#accountForm td:nth-of-type(1)')
		@formSignup = $('<form></form>').appendTo('#accountForm td:nth-of-type(2)')

		@formLogin.append('<span>Your username</span><input type="text" name="username"/>')
		@formLogin.append('<span>Your password</span><input type="password" name="password"/>')
		@formLogin.append('<input type="submit" value="Let\'s fight"/>')

		@formSignup.append('<span>Your username</span><input type="text" name="username"/>')
		@formSignup.append('<span>Your email adress</span><input type="email" name="email"/>')
		@formSignup.append('<span>Your password</span><input type="password" name="password"/>')
		@formSignup.append('<input type="submit" value="Enroll"/>')

		# Center the popup.
		left = ($(window).width()-@popup.width()) / 2 
		top = ($(window).height()-@popup.height()) / 2
		@popup.css
			'position': 'absolute'
			'left': left
			'top': top

		# Setup form validation.
		$('input[type="submit"]', @popup).click (event) =>
			event.preventDefault()
			alert 'Nope.'

		# Fade in popup, fade out everything else.
		@cache.fadeIn(300)
		@popup.fadeIn(300, () =>

			# Close popup when clicking occurs outside of it.
			@popup.click (event) ->
				event.stopPropagation();
			$(document).click (event) =>

				@cache.fadeOut(300)
				@popup.fadeOut(300, () =>
					window.accountForm = null
					@popup.remove()
				)
		)

# Exports
window.AccountForm = AccountForm
