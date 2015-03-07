Mine = require('./mine').Mine

class BonusMine
  type: 'mine'

  constructor: (@game, @bonus) ->
    @mines = @game.prefs.bonus.mine.mineCount

  use: () ->
    return if @mines <= 0

    @game.newGameObject (id) =>
      dropPos = {x: @bonus.pos.x, y: @bonus.pos.y}
      @game.mines[id] = new Mine(id, @game, @bonus.holder, dropPos)

    # Decrease mine count.
    --@mines

    # Clean up if there is no more mine.
    if @mines is 0
      @bonus.holder.releaseBonus()
      @bonus.setState 'dead'

exports.BonusMine = BonusMine
exports.constructor = BonusMine
exports.type = 'bonusMine'
