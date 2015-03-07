class BonusBoost
  type: 'boost'

  constructor: (@game, @bonus) ->

  use: () ->
    ship = @bonus.holder

    # Boost da ship.
    ship.boost = @game.prefs.bonus.boost.boostFactor
    ship.boostDecay = 0

    ship.flagNextUpdate('boost')

    # Send event to client.
    @game.events.push
      type: 'ship boosted'
      id: ship.id

    # Setup decay for this boost and overwrite previous boost.
    ship.bonusTimeouts.boostDecay =
      duration: @game.prefs.bonus.boost.boostDuration
      onTimeout: (ship) =>
        ship.boostDecay = @game.prefs.bonus.boost.boostDecay

    # Clean up.
    ship.releaseBonus()
    @bonus.setState 'dead'

exports.BonusBoost = BonusBoost
exports.constructor = BonusBoost
exports.type = 'bonusBoost'
