class Chat
	constructor: (@client) ->

		@chat = $('#chat')
		@input = $('#chatInput')

		@setInputHandlers()

	setInputHandlers: () ->

		$(document).keyup ({keyCode}) =>
			return if @client.menu.isOpen()

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
		@client.socket.emit 'message',
				playerId: @client.playerId
				message: message

	receive: (data) ->
		message = data.message
		name = @client.ships[data.shipId].name
		color = @client.ships[data.shipId].color

		# Append the message to the chat.
		@chat.append('<div style="display:none"><span style="color:hsl('+color[0]+','+color[1]+'%,'+color[2]+'%)">'+name+'</span> '+message+'</div>')
		line = @chat.find('div:last')
		line.fadeIn(300)
		
		# Program its disappearance.
		setTimeout( (() ->
			line.animate({opacity: 'hide', height: 'toggle'}, 300, () -> line.detach())),
			8000)

# Exports
window.Chat = Chat
