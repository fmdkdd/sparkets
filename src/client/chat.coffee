class Chat
	constructor: () ->

		@chat = $('#chat')
		@input = $('#chatInput')

		@setInputHandlers()

	setInputHandlers: () ->

		$(document).keyup ({keyCode}) =>
			# Open the chat when T is pressed.
			if keyCode is 84 and not @isOpen()
				@open()

			# Close the chat when Escape is pressed.
			else if keyCode is 27 and @isOpen()
				@close()

			# Send the message when Enter is pressed.
			else if keyCode is 13 and @isOpen()
				@send(@input.val())
				@close()

	open: () ->
		@input.removeClass('hidden')
		@input.addClass('visible')

		@input.val('')
		@input.focus()

	close: () ->
		@input.removeClass('visible')
		@input.addClass('hidden')

		@input.blur()

	isOpen: () ->
		@input.hasClass('visible')

	send: (message) ->
		console.info message
		window.socket.emit 'message',
				playerId: playerId
				message: message

	receive: (data) ->
		message = data.message
		name = window.ships[data.shipId].name
		color = window.ships[data.shipId].color

		@chat.append('<span>'+name+': '+message+'</span>')

# Exports
window.Chat = Chat
