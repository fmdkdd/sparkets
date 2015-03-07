Grenade = require('./grenade').Grenade

class BonusGrenade
  type: 'grenade'

  constructor: (@game, @bonus) ->

  use: () ->

    # Release the initial grenade.
    @game.newGameObject (id) =>
      dropPos = {x: @bonus.pos.x, y: @bonus.pos.y}
      velocity = {x: 0, y: 0}
      @game.grenades[id] = new Grenade(id, @game, @bonus.holder, dropPos, velocity, yes)

    # Clean up.
    @bonus.holder.releaseBonus()
    @bonus.setState 'dead'

exports.BonusGrenade = BonusGrenade
exports.constructor = BonusGrenade
exports.type = 'bonusGrenade'
