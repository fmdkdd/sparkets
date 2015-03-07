class BonusStealth
  type: 'stealth'

  constructor: (@game, @bonus) ->

  use: () ->
    ship = @bonus.holder

    ship.invisible = yes
    ship.flagNextUpdate('invisible')

    # Setup and overwrite previous stealth cancel.
    ship.bonusTimeouts.stealthEffect =
      duration: @game.prefs.bonus.stealth.duration
      onTimeout: (ship) ->
        ship.invisible = no
        ship.flagNextUpdate('invisible')

    # Clean up.
    ship.releaseBonus()
    @bonus.setState 'dead'

exports.BonusStealth = BonusStealth
exports.constructor = BonusStealth
exports.type = 'bonusStealth'
