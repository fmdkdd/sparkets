Shield = require('./shield').Shield

class BonusShield
  type: 'shield'

  constructor: (@game, @bonus) ->

  use: () ->
    # Cancel current shield
    if @bonus.holder.shield
      @bonus.holder.shield.cancel()

    @game.newGameObject (id) =>
      @bonus.holder.shield = @game.shields[id] = new Shield(id, @game, @bonus.holder)

    # Clean up.
    @bonus.holder.releaseBonus()
    @bonus.setState 'dead'

exports.BonusShield = BonusShield
exports.constructor = BonusShield
exports.type = 'bonusShield'
