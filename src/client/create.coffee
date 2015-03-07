$(document).ready () ->

  window.spriteManager = new SpriteManager()

  window.ranges = []
  window.selectionBoxes = []
  window.bonusBoxes = []

  # Setup tabbed panels.
  $('#form .tab').click (event) ->

    # Do not follow the clicked link.
    event.preventDefault()

    oldTab = $('#form .tab.selected')
    if oldTab.length > 0

      # Unselect the current tab.
      oldTab.removeClass('selected')

      # Hide the current panel.
      $('#panel' + oldTab.attr('id').substr(@.id.length-1, 1)).hide()

    # Select the new tab
    $(@).addClass('selected')

    # Display the new panel.
    $('#panel' + @.id.substr(@.id.length-1, 1)).show()

  #
  window.presets =
    mapSize:
      'tiny': 1000
      'small': 1500
      'medium': 2000
      'large': 5000
      'epic': 10000

    'planet.density':
      'few': .15
      'normal': .35
      'plenty': .5
      'excessive': .7

    'bonus weight':
      'none': 0
      'rare': 1
      'regular': 5
      'plenty': 10

  # Fill the form.

  # Wrap a two cells tr inside a container and return the second cell.
  entry = (container, label) ->
    tr = (container) ->
      $('<tr class="entry"></tr>').appendTo(container)

    c = $('<td><span>' + label + '</span></td>').appendTo(tr(container))
    $('<td></td>').insertAfter(c)

  # Give the label of the `line`th line of the `panel`th panel.
  label = (panel, line) ->
    $('#panel'+ panel + ' > table > tbody > tr:nth-child(' + line + ') > td:first-child span')

  # First panel: general options.

  new Tooltip(label(1, 1), 'The name of the game in the game list. Will also define the game URL.')

  new Range(entry('#panel1 table', 'Game duration'),
    'duration', 3, 20, 1, 5, ' minutes')
  new Tooltip(label(1, 2), 'The duration of the game in minutes.')

  # Second panel: map.

  window.selectionBoxes.push new SelectionBox(entry('#panel2 > table', 'Map size'),
    'mapSize', Object.keys(window.presets['mapSize']), 2)
  new Tooltip(label(2, 1), 'blabla')

  window.selectionBoxes.push new SelectionBox(entry('#panel2 > table', 'Planet density'),
    'planet.density', Object.keys(window.presets['planet.density']), 1)
  new Tooltip(label(2, 2), 'blabla')

  # Third panel: bonus.

  cell = $('#panel3 tr:nth-child(1) td:nth-child(2)')

  # Give the nth bonus.
  bonus = (n) ->
    cell.find('.bonusBox:nth-of-type(' + n + ')')

  window.bonusBoxes.push new BonusBox(cell, 'bonus.bonusType.mine.weight', 'bonusMine')
  new Tooltip(bonus(1), 'Mine blablablaaa')

  window.bonusBoxes.push new BonusBox(cell, 'bonus.bonusType.tracker.weight', 'bonusTracker')
  new Tooltip(bonus(2), 'Tracker blablablaaa')

  window.bonusBoxes.push new BonusBox(cell, 'bonus.bonusType.boost.weight', 'bonusBoost')
  new Tooltip(bonus(3), 'Boost blablablaaa')

  window.bonusBoxes.push new BonusBox(cell, 'bonus.bonusType.shield.weight', 'bonusShield')
  new Tooltip(bonus(4), 'Shield blablablaaa')

  window.bonusBoxes.push new BonusBox(cell, 'bonus.bonusType.EMP.weight', 'bonusEMP')
  new Tooltip(bonus(5), 'EMP blablablaaa')

  window.bonusBoxes.push new BonusBox(cell, 'bonus.bonusType.stealth.weight', 'bonusStealth')
  new Tooltip(bonus(6), 'Stealth blablablaaa')

  window.bonusBoxes.push new BonusBox(cell, 'bonus.bonusType.grenade.weight', 'bonusGrenade')
  new Tooltip(bonus(7), 'Grenade blablablaaa')

  new Range(entry('#panel3 > table', 'Drop wait'),
    'bonus.waitTime', 1000, 10000, 1000, 5000, ' milliseconds')
  new Tooltip(label(3, 2), 'blabla')

  new Range(entry('#panel3 > table', 'Activation wait'),
    'bonus.states.incoming.countdown', 500, 5000, 500, 2000, ' milliseconds')
  new Tooltip(label(3, 3), 'blabla')

  new Range(entry('#panel3 > table', 'Max allowed'),
    'bonus.maxCount', 0, 20, 1, 10, ' bonuses')
  new Tooltip(label(3, 4), 'blabla')

  new Range(entry('#panel3 > table', 'Mines in bonus'),
    'bonus.mine.mineCount', 1, 10, 1, 2, ' mines')
  new Tooltip(label(3, 5), 'blabla')

  # Fourth panel: advanced options (aka 'things we didn't know where to put').

  new Range(entry('#panel4 > table', 'Speed'),
    'ship.speed', 0.1, 1.01, 0.1, 0.3)
  new Tooltip(label(4, 1), 'blabla')

  new Range(entry('#panel4 > table', 'Friction decay'),
    'ship.frictionDecay', 0, 1, 0.01, 0.97)
  new Tooltip(label(4, 2), 'blabla')

  new Range(entry('#panel4 > table', 'Bot count'),
    'bot.count', 0, 10, 1, 1)
  new Tooltip(label(4, 3), 'blabla')

  # Connect to server and setup callbacks.
  window.socket = io.connect()

  window.socket.on 'connect', () ->
    # Do something?

  window.socket.on 'game already exists', () ->
    $('#error').html('Name already exists')

  window.socket.on 'game created', (data) ->
    # Redirect to the client page.
    window.location.replace('../play/#' + data.id)

  window.socket.on 'game list', (data) ->
    idList = Object.keys(data)
    if idList.length > 0
      window.gameListRegexp = new RegExp('^(' + idList.join('|') + ')$')
    else
      window.gameListRegexp = null

  # Setup form handling.
  $('input[type="text"]').keyup (event) =>
    if window.gameListRegexp? and event.target.value.match(window.gameListRegexp)
      $('#error').html('Name already exists')
      $('input[type="submit"]').attr('disabled', 'disabled')
      console.info 'no'
    else
      $('#error').html('')
      $('input[type="submit"]').removeAttr('disabled')
      console.info 'ok'

  $('input[type="submit"]').click (event) ->
    event.preventDefault()
    data = gatherValues()

    # Prepare game options.
    opts =
      id: data.id
      prefs: data
    delete data.id

    window.socket.emit 'create game', opts, () ->
      # Clear and unfocus game name input on creation.
      nameInput = $('#panel1 input[name="id"]')
      nameInput.val('')
      nameInput.blur()

  gatherValues = () ->
    insert = (obj, name, val) ->
      [prop, rest...] = name.split('.')

      if rest.length > 0
        obj[prop] = {} if not obj[prop]?
        insert(obj[prop], rest.join('.'), val)
      else
        obj[name] = val

    prefs = {}
    for input in $('#form').find('input')
      if input.name? and input.value?
        switch input.type
          when 'text'
            insert(prefs, input.name, input.value)
          when 'range'
            insert(prefs, input.name, parseFloat(input.value))

    for sb in @selectionBoxes
      insert(prefs, sb.name, window.presets[sb.name][sb.value()])

    for bb in @bonusBoxes
      insert(prefs, bb.name, window.presets['bonus weight'][bb.state])

    return prefs

  # Setup log in and sign up forms.
  $('#login, #signup').click (event) =>
    return if window.accountForm?

    # Popup the forms.
    new AccountForm()

    # Focus on the appropriate field.
    if event.target.id is 'login'
      window.accountForm.formLogin.find('input[name="username"]').focus()
    else
      window.accountForm.formSignup.find('input[name="username"]').focus()

  # Make page content unselectable to prevent inopportune selection
  # when repidly clicking on bonuses.
  document.body.onselectstart = () -> false

  # Request game list.
  window.socket.emit 'get game list'
