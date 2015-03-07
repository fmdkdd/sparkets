logger = require('../logger').static

warn = (msg) -> logger.warn msg

exports.mixin = () ->

  @updateState = (step) ->

    if @countdown?
      @countdown -= @game.prefs.timestep * step
      @nextState() if @countdown <= 0

  @nextState = () ->

    @state = @game.prefs[@type].states[@state].next
    @countdown = @game.prefs[@type].states[@state].countdown
    @flagNextUpdate('state')

  @setState = (state) ->

    if @game.prefs[@type].states[state]?
      unless @state is state
        @state = state
        @countdown = @game.prefs[@type].states[state].countdown
        @flagNextUpdate('state')
    else
      warn "#{@type} tried to switch to invalid state \"#{state}\""

  @
