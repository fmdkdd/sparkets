class Chat
	constructor: (@client) ->

		@chat = $('#chat')
		@input = $('#chatInput')

		@displayDuration = 8000

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
				message: message

	display: (data) ->

		colorize = (text, color) ->
			'<span style="color:hsl('+color[0]+','+color[1]+'%,'+color[2]+'%)">'+text+'</span>'

		switch data.type
			when 'message'
				console.info data
				name = @client.ships[data.id].name
				color = @client.ships[data.id].color
				img = '<img width="30" src="/img/iconTalk.svg"/>'
				message = colorize(name, color) + ' ' + img + ' "' + data.message + '"'

			when 'ship crashed'
				name = @client.ships[data.id].name or 'unnamed'
				color = @client.ships[data.id].color or 'black'
				img = '<img width="30" src="/img/iconDeath.svg"/>'
				message = colorize(name, color) + ' ' + img

			when 'ships both crashed'
				name1 = @client.ships[data.id1].name or 'unnamed'
				color1 = @client.ships[data.id1].color or 'black'
				name2 = @client.ships[data.id2].name or 'unnamed'
				color2 = @client.ships[data.id2].color or 'black'
				img = '<img width="30" src="/img/iconDeath.svg"/>'
				message = colorize(name1, color1) + ' + ' + colorize(name2, color2) + ' ' + img

			when 'ship killed'
				name1 = @client.ships[data.idKiller].name or 'unnamed'
				color1 = @client.ships[data.idKiller].color or 'black'
				name2 = @client.ships[data.idKilled].name or 'unnamed'
				color2 = @client.ships[data.idKilled].color or 'black'
				img = '<img width="30" src="/img/iconKill.svg"/>'
				message = colorize(name1, color1) + ' ' + img + ' ' + colorize(name2, color2)

		# Append the message to the chat.
		line = $('<div style="display:none">' + message + '</div>').appendTo(@chat)
		line.fadeIn(300)

		# Program its disappearance.
		setTimeout( (() =>
			line.animate({opacity: 'hide', height: 'toggle'}, 300, () -> line.detach())),
			@displayDuration)

# Exports
window.Chat = Chat
