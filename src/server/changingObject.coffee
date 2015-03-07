class ChangingObject
  constructor: () ->
    @_fullUpdateProps = {}
    @_nextUpdateProps = {}

  # Flag `prop' property for a full update. Whenever a full update is
  # sent to a client, only properties flagged for a full update will
  # be part of the message.
  #
  # A full update is currently sent only to new players right after
  # they are connected. Useful for sending properties only once to
  # clients.
  flagFullUpdate: (prop) ->
    @_fullUpdateProps[prop] = yes

  unflagFullUpdate: (prop) ->
    delete @_fullUpdateProps[prop]

  unflagAllFullUpdate: () ->
    @_fullUpdateProps = {}

  # Flag `prop' property to be sent at the next update. The next tick
  # update will gather all properties flagged for the next update and
  # send them to all connected players.
  #
  # Since tick updates are very frequent and saving bandwidth is
  # critical, flagging for a next update should be done most
  # economically. Properties that do not need to be sent more than
  # once per client should be flagged for a full update instead.
  # Whenever possible, flag only necessary properties for a next
  # update and let the client infer the rest.
  flagNextUpdate: (prop) ->
    @_nextUpdateProps[prop] = yes

  unflagNextUpdate: (prop) ->
    delete @_nextUpdateProps[prop]

  unflagAllNextUpdate: () ->
    @_nextUpdateProps = {}

  # Return this object with only the properties flagged for next
  # update.
  nextUpdateObj: () ->
    @constructObj(@_nextUpdateProps)

  # Return this object with only the properties flagged for full
  # update.
  fullUpdateObj: () ->
    @constructObj(@_fullUpdateProps)

  constructObj: (flag) ->
    obj = {}
    for prop of flag
      @copyProp(@, obj, prop)
    return obj

  copyProp: (source, target, prop) ->
    [name, rest...] = prop.split('.')

    if rest.length > 0
      target[name] = {} unless target[name]?
      @copyProp(source[name], target[name], rest.join('.'))
    else
      target[prop] = source[prop]


exports.ChangingObject = ChangingObject
