class Client
  constructor: () ->

    # Server
    @socket = null

    # Graphics
    @ctxt = document.getElementById('canvas').getContext('2d')
    @canvasSize = {w: 0, h: 0}
    @mapSize = null
    @view = {x: 0, y: 0}

    @spriteManager = new SpriteManager()

    # Time
    @now = null
    @sinceLastUpdate = null

    @shipId = null
    @localShip = null

    @gameObjects = {}
    @ships = {}
    @bonuses = {}

    @effects = []

    @keys = {}

    # User preferences
    @displayNames = no

    # Game logic
    @maxBulletLength = 30

    # Debugging
    @showHitBoxes = no
    @showMapBounds = no
    @showFPS = no

    @menu = new Menu(@)
    @menu.restoreLocalPreferences()

    @chat = new Chat(@)

    # Connect to server and set callbacks.
    # FIXME: websocket port number is hardcoded
    @socket = new WebSocket('ws:' + window.location.hostname + ':12346')

    # Setup a connexion timeout to redirect to homepage in case of
    # nonexistent games.
    @connectionTimeout = setTimeout( ( () ->
      url = 'http://' + window.location.hostname + ':' + window.location.port
      window.location.replace(url)), 1500)

    # Bind socket events.
    @socket.addEventListener 'open', () =>
      @onConnect()

    @socket.addEventListener 'close', () =>
      @onDisconnect()

    @socket.addEventListener 'message', (raw) =>
      msg = message.decode(raw.data)

      switch msg.type
        when message.CONNECTED
          console.log('received connected', msg.content)
          @onConnected msg.content

        when message.OBJECTS_UPDATE
          @onObjectsUpdate msg.content

        when message.SHIP_CREATED
          console.log('received connected', msg.content)
          @onShipCreated msg.content

        when message.PLAYER_SAYS
          console.log('received PLAYER_SAYS', msg.content)
          @onPlayerMessage msg.content

        when message.PLAYER_QUITS
          @onPlayerQuits msg.content

        when message.GAME_END
          @onGameEnd msg.content

    # Resize canvas and surrounding margins.
    #
    # The canvas stays at aspect ratio 16:10, with max resolution at
    # 960:600.  Resizing the window will eat into the empty space
    # surrounding the canvas first, then the canvas will shrink
    # while keeping its aspect ratio.
    $(window).resize (event) =>
      canvasWidth = Math.min(window.innerWidth, 960)
      canvasHeight = Math.min(window.innerHeight, 600)

      # Keep aspect ratio
      ratio = canvasWidth / canvasHeight
      if ratio < 1.6
        canvasHeight = 10/16 * canvasWidth
      else if ratio > 1.6
        canvasWidth = 16/10 * canvasHeight

      # The canvas MUST be resized using the width/height
      # attributes, and not merely with CSS, to avoid scaling.
      @canvasSize.w = document.getElementById('canvas').width = canvasWidth
      @canvasSize.h = document.getElementById('canvas').height = canvasHeight

      # Center canvas horizontally if there is enough space
      horizSpace = Math.max(window.innerWidth - canvasWidth, 0)
      $('#canvas').css
        'margin-left': horizSpace/2
        'margin-right': horizSpace/2

      # Add top margin if there is enough space
      vertSpace = Math.max(window.innerHeight - canvasHeight, 0)
      $('#canvas').css('margin-top': vertSpace/3)

    # Manually trigger a resize event to set everything in place
    $(window).resize()


    @disappearingCursorMode()
    @hideCursor()

  # Hide the cursor when the mouse is inactive.
  disappearingCursorMode: () ->

    # WARNING: hiding and showing the cursor triggers a mousemove
    # event, @phonyMouseMovePassed let us detect and ignore that
    # unwanted effect.
    @phonyMouseMovePassed = yes

    @hideCursor()
    $(document).mousemove () =>

      if @phonyMouseMovePassed
        clearTimeout(@hideCursorTimeout) if @hideCursorTimeout?
        @hideCursorTimeout = setTimeout((() => @hideCursor()), 1000)
        @showCursor()

      @phonyMouseMovePassed = yes

  staticCursorMode: () ->
    clearTimeout(@hideCursorTimeout) if @hideCursorTimeout?
    $(document).unbind('mousemove')
    @showCursor()

  showCursor: () ->
    $('*').css({cursor: 'default'})

  hideCursor: () ->
    $('*').css({cursor: 'none'})
    @phonyMouseMovePassed = no

  # Setup input callbacks and launch game loop.
  go: () ->

    # Show the menu the first time.
    if not window.localStorage['sparkets.tutorial']?
      @menu.open()
      window.localStorage['sparkets.tutorial'] = true

    # Use the game event handler.
    @setInputHandlers()

    @renderLoop(@showFPS)

  setInputHandlers: () ->
    # Space, left, up, right, A, Z
    processedKeys = [32, 37, 38, 39, 65, 90]

    # Send key presses and key releases to the server.
    $(document).keydown (event) =>
      return unless event.keyCode in processedKeys

      if not @keys[event.keyCode]? or @keys[event.keyCode] is off
        @keys[event.keyCode] = on
        message.send(@socket, message.KEY_DOWN, event.keyCode)

    $(document).keyup ({keyCode}) =>
      return unless keyCode in processedKeys

      @keys[keyCode] = off
      message.send(@socket, message.KEY_UP, keyCode)

  renderLoop: (showFPS) ->

    # RequestAnimationFrame API
    # http://paulirish.com/2011/requestanimationframe-for-smart-animating/
    requestAnimFrame = ( () =>
      window.requestAnimationFrame       or
      window.webkitRequestAnimationFrame or
      window.mozRequestAnimationFrame    or
      window.oRequestAnimationFrame      or
      window.msRequestAnimationFrame     or
      (callback, element) -> setTimeout(callback, 1000 / 60) )()

    currentFPS = 0
    frameCount = 0
    lastFPSupdate = 0
    lastTime = 0

    render = (time) =>
      # Setup next update.
      requestAnimFrame(render)

      # For browsers which do not pass the time argument.
      time ?= Date.now()

      # Update FPS every second
      if (time - lastFPSupdate > 1000)
        currentFPS = frameCount
        frameCount = 0
        lastFPSupdate = time
        console.info(currentFPS) if showFPS

      # Pass current time and time since last update to callback.
      @update(time, time - lastTime)

      # Another frame blit you must.
      ++frameCount

      # Update time of the last update.
      lastTime = time

    requestAnimFrame(render)

  # Game loop!
  update: (time, sinceUpdate) ->

    # Update time variables.
    @sinceLastUpdate = sinceUpdate
    @now = time

    # Update and cleanup objects.
    for id, obj of @gameObjects
      obj.update()
      if obj.serverDelete and obj.clientDelete
        @deleteObject id

    # Update and cleanup visual effects.
    effects = []
    for e in @effects
      e.update()
      if not e.deletable()
        effects.push e
    @effects = effects

    # Draw scene.
    @redraw(@ctxt)

  boxInView: (x, y, r) ->
    @inView(x-r, y-r) or
    @inView(x-r, y+r) or
    @inView(x+r, y-r) or
    @inView(x+r, y+r)

  inView: (x, y) ->
    @view.x <= x <= @view.x + @canvasSize.w and
    @view.y <= y <= @view.y + @canvasSize.h

  # Clear canvas and draw everything.
  # Not efficient, but we don't have that many objects.
  redraw: (ctxt) ->
    ctxt.clearRect(0, 0, @canvasSize.w, @canvasSize.h)

    # Draw everything centered around the player when he's alive.
    unless @localShip.state in ['dead', 'ready']
      @centerView(@localShip)

    ctxt.save()
    ctxt.translate(-@view.x, -@view.y)

    @drawMapBounds(ctxt) if @showMapBounds

    # Draw all objects.
    for idx, obj of @gameObjects
      @drawObject(ctxt, obj) if obj.inView()

    # Draw all visual effects.
    for e in @effects
      e.draw(ctxt) if e.inView()

    # Draw outside of the map bounds.
    @drawInfinity ctxt

    # View translation doesn't apply to UI.
    ctxt.restore()

    # Draw UI
    @drawRadar(ctxt) if @localShip? and @localShip.state is 'alive'

  drawObject: (ctxt, obj, offset) ->
    ctxt.save()
    obj.draw(ctxt, offset)
    ctxt.restore()
    if @showHitBoxes
      ctxt.save()
      obj.drawBoundingBox(ctxt)
      obj.drawHitbox(ctxt)
      ctxt.restore()

  drawMapBounds: (ctxt) ->
    ctxt.save()
    ctxt.lineWidth = 2
    ctxt.strokeStyle = '#dae'
    ctxt.strokeRect(0, 0, @mapSize, @mapSize)
    ctxt.restore()

  centerView: (obj) ->
    @view.x = obj.pos.x - @canvasSize.w/2
    @view.y = obj.pos.y - @canvasSize.h/2

  drawRadar: (ctxt) ->
    for id, ship of @ships
      unless id is @shipId or ship.state in ['dead', 'ready']
        ctxt.save()
        ship.drawOnRadar(ctxt)
        ctxt.restore()

    for id, bonus of @bonuses
      if bonus.state isnt 'dead'
        ctxt.save()
        bonus.drawOnRadar(ctxt)
        ctxt.restore()

    true

  drawInfinity: (ctxt) ->

    # Can the player see the left, right, top and bottom voids?
    left = @view.x < 0
    right = @view.x > @mapSize - @canvasSize.w
    top = @view.y < 0
    bottom = @view.y > @mapSize - @canvasSize.h

    visibility = [[left and top,    top,    right and top]
                  [left,            off,  right],
                  [left and bottom, bottom, right and bottom]]

    for i in [0..2]
      for j in [0..2]
        if visibility[i][j] is on
          # Translate to the adequate quadrant.
          offset =
            x: (j-1)*@mapSize
            y: (i-1)*@mapSize

          ctxt.save()
          ctxt.translate(offset.x, offset.y)

          # Draw all visible objects in it.
          for id, obj of @gameObjects
            @drawObject(ctxt, obj, offset) if obj.inView(offset)

          # Draw all visible effects
          for e in @effects
            e.draw(ctxt, offset) if e.inView(offset)

          # Quadrant is done drawing.
          ctxt.restore()

    return true

  newObject: (id, type, obj) ->
    switch type
      when 'ship'
        @ships[id] = new Ship(@, obj)
      when 'bullet'
        new Bullet(@, obj)
      when 'mine'
        new Mine(@, obj)
      when 'grenade'
        new Grenade(@, obj)
      when 'EMP'
        new EMP(@, obj)
      when 'shield'
        new Shield(@, obj)
      when 'bonus'
        @bonuses[id] = new Bonus(@, obj)
      when 'planet', 'moon'
        new Planet(@, obj)
      when 'rope'
        new Rope(@, obj)
      when 'tracker'
        new Tracker(@, obj)

  deleteObject: (id) ->
    type = @gameObjects[id].type

    switch type
      when 'ship'
        delete @ships[id]
      when 'bonus'
        delete @bonuses[id]

    delete @gameObjects[id]

  closestGhost: (sourcePos, targetPos) ->
    bestPos = null
    bestDistance = Infinity

    for i in [-1..1]
      for j in [-1..1]
        ox = targetPos.x + i * @mapSize
        oy = targetPos.y + j * @mapSize
        d = utils.distance(sourcePos.x, sourcePos.y, ox, oy)
        if d < bestDistance
          bestDistance = d
          bestPos = {x: ox, y: oy}

    return bestPos

  onConnect: () ->
    console.info "Connected to WebSocket server."
    clearTimeout(@connectionTimeout)

  onDisconnect: () ->
    console.info "Aaargh! Disconnected!"

  # When receiving our id from the server.
  onConnected: (data) ->
    @gameStartTime = data.startTime

    # Copy useful game preferences from the server.
    @mapSize = data.serverPrefs.mapSize
    @minPower = data.serverPrefs.ship.minPower
    @maxPower = data.serverPrefs.ship.maxPower
    @gameDuration = data.serverPrefs.duration
    @cannonCooldown = data.serverPrefs.ship.cannonCooldown

    @serverPrefs = data.serverPrefs

    @menu.sendPreferences()

    message.send(@socket, message.CREATE_SHIP)

  onShipCreated: (shipId) ->
    @shipId = shipId
    @localShip = @gameObjects[@shipId]

    # Set the color of the ship preview in menu to our ship color.
    @menu.currentColor = @localShip.color
    @menu.updatePreview(@localShip.color)

    @go()

  # When receiving world update data.
  onObjectsUpdate: (data) ->
    for id, obj of data.objects
      if not @gameObjects[id]?
        if obj.type?
          @gameObjects[id] = @newObject(id, obj.type, obj)
      else
        @gameObjects[id].serverUpdate(obj)

    if data.events?
      for e in data.events
        @handleEvent(e)

  handleEvent: (event) ->
    switch event.type
      when 'message'
        @chat.display(event)

      when 'ship crashed'
        @gameObjects[event.id].explosionEffect()
        @gameObjects[event.id].dislocationEffect()

      when 'ships both crashed'
        @gameObjects[event.id1].explosionEffect()
        @gameObjects[event.id1].dislocationEffect()
        @gameObjects[event.id2].explosionEffect()
        @gameObjects[event.id2].dislocationEffect()

      when 'ship killed'
        @gameObjects[event.idKilled].explosionEffect()
        @gameObjects[event.idKilled].dislocationEffect()

      when 'ship boosted'
        @gameObjects[event.id].boostEffect()

      when 'bullet died'
        @gameObjects[event.id].explosionEffect()

      when 'mine exploded'
        @gameObjects[event.id].explosionEffect()

      when 'bonus used'
        @gameObjects[event.id].openingEffect()

      when 'bonus exploded'
        @gameObjects[event.id].openingEffect()
        @gameObjects[event.id].explosionEffect()

      when 'rope exploded'
        return unless @gameObjects[event.id]?
        @gameObjects[event.id].explosionEffect()

      when 'tracker activated'
        @gameObjects[event.id].trailEffect()
        @gameObjects[event.id].boostEffect()

      when 'tracker exploded'
        @gameObjects[event.id].explosionEffect()

      when 'grenade exploded'
        @gameObjects[event.id].explosionEffect()

      when 'EMP charging'
        @gameObjects[event.id].chargingEffect()

      when 'EMP exploded'
        @gameObjects[event.id].wavesEffect()

  # When a player sent a chat message.
  onPlayerMessage: (data)->
    @chat.display(data)

  # When another player leaves.
  onPlayerQuits: (data) ->


  onGameEnd: () ->
    @gameEnded = yes
    @menu.open()

# Entry point.
$(document).ready () ->
  window.client = new Client()
