message = {}

messageTypes = [
  'OBJECTS_UPDATE'
  'KEY_DOWN'
  'KEY_UP'
  'CHAT_MESSAGE'
  'PLAYER_SAYS'
  'PREFERENCES_CHANGED'
  'CONNECTED'
  'CREATE_SHIP'
  'SHIP_CREATED'
  'PLAYER_QUITS'
  'GAME_END'
]

buildMessageEnum = () ->
  id = 0
  message[m] = id++ for m in messageTypes
buildMessageEnum()

message.send = (socket, type, content) ->
  socket.send(message.encode(type, content))

message.broadcast = (socketServer, type, content) ->
  socketServer.broadcast(message.encode(type, content))

message.encode = (type, content) ->
  #console.log('encoding', type, content)

  switch type
    when message.PLAYER_SAYS
      msg = [type, [
        content.shipId,
        content.message ]]

    when message.OBJECTS_UPDATE
      msg = [type, [content.objects]]
      msg[1].push(content.events) if content.events?

    when message.CREATE_SHIP, message.GAME_END, message.HELLO
      msg = [type]

    else msg = [type, content]

  m = JSON.stringify msg
  #console.log('encoded message', m)
  m

message.decode = (data) ->
  [type, content] = JSON.parse data

  switch type
    when message.PLAYER_SAYS
      msg = {
        type: type
        content: {
          shipId: content[0]
          message: content[1] }}

    when message.OBJECTS_UPDATE
      msg = {
        type: type
        content: {
          objects: content[0]
          events: content[1] }}

    when message.CREATE_SHIP, message.GAME_END, message.HELLO
      msg = {type: type}

    else msg = {type: type, content: content}

  #console.log('decoded message', msg)

  msg

module?.exports = message
window?.message = message
