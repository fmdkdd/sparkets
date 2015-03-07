ChangingObject = require('./changingObject').ChangingObject
stateMachineMixin = require('./stateMachine').mixin
utils = require '../utils'

class EMP extends ChangingObject

  stateMachineMixin.call(@prototype)

  constructor: (@id, @game, @owner) ->
    super()

    # Send these properties to new players.
    @flagFullUpdate('type')
    @flagFullUpdate('color')
    @flagFullUpdate('state')
    @flagFullUpdate('pos')
    @flagFullUpdate('radius')
    @flagFullUpdate('serverDelete')
    if @game.prefs.debug.sendHitBoxes
      @flagFullUpdate('boundingBox')
      @flagFullUpdate('hitBox')

    @type = 'EMP'
    @flagNextUpdate('type')

    # Sport the owner's colors.
    @color = @owner.color
    @flagNextUpdate('color')

    # Initial State.
    @setState 'charging'
    @flagNextUpdate('state')

    # Let the client now that the EMP is charging.
    @game.events.push
      type: 'EMP charging'
      id: @id

    @radius = 0
    @flagNextUpdate('radius')

    @pos =
      x: @owner.pos.x
      y: @owner.pos.y
    @flagNextUpdate('pos')

    @boundingBox =
      x: @pos.x
      y: @pos.y
      radius: @radius
    @hitBox =
      type: 'circle'
      x: @pos.x
      y: @pos.y
      radius: @radius
    if @game.prefs.debug.sendHitBoxes
      @flagNextUpdate('boundingBox')
      @flagNextUpdate('hitBox')

  tangible: () ->
    @state is 'exploding'

  move: () ->

    # Only synchronize the EMP position with the owner's
    # one when charging.
    if @state is 'charging' or @state is 'exploding'

      @pos =
        x: @owner.pos.x
        y: @owner.pos.y
      @flagNextUpdate('pos')

      @boundingBox.x = @hitBox.x = @owner.pos.x
      @boundingBox.y = @hitBox.y = @owner.pos.y
      if @game.prefs.debug.sendHitBoxes
        @flagNextUpdate('boundingBox')
        @flagNextUpdate('hitBox')

  update: (step) ->

    oldState = @state
    @updateState(step)

    switch @state

      when 'charging'

        # Stop the EMP if the owner died.
        if @owner.state is 'dead'
          @setState 'dead'

      when 'exploding'

        # Let the client know that the EMP just exploded.
        if oldState isnt @state
          @game.events.push
            type: 'EMP exploded'
            id: @id

        progress = 1 - (@countdown / @game.prefs.EMP.states.exploding.countdown)
        if progress <= 1
          @radius = @game.prefs.EMP.effectRadius * progress
          @flagNextUpdate('radius')

          @boundingBox.radius = @hitBox.radius = @radius
          if @game.prefs.debug.sendHitBoxes
            @flagNextUpdate('boundingBox.radius')
            @flagNextUpdate('hitBox.radius')

      # The explosion is over.
      when 'dead'
        @serverDelete = yes
        @flagNextUpdate('serverDelete')

exports.EMP = EMP
