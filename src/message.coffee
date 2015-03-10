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
  JSON.stringify([type, content])

message.decode = (data) ->
  [type, content] = JSON.parse(data)
  {type: type, content: content}

module?.exports = message
window?.message = message
