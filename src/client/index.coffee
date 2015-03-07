$(document).ready () ->

  # Server.
  window.socket = null

  # Connect to server and set callbacks.
  window.socket = io.connect()

  # Grab the game list every minute.
  setInterval( (() =>
    window.socket.emit('get game list')), 60 * 1000)

  # Fetch the game list at first connection.
  window.socket.on 'connect', () =>
    window.socket.emit 'get game list'

  # Update list of running games.
  window.socket.on 'game list', (data) =>
    $('#gameList').empty()

    minutesLeft = (start, duration) ->
      new Date(duration - (Date.now() - start)).getMinutes()

    for id, game of data
      href = '/play/#' + id
      $('#gameList').append('<tr>
        <td><a href="' + href + '">' + id + '</a></td>
        <td>' + game.players + '</td>
        <td>' + minutesLeft(game.startTime, game.duration * 60 * 1000) + ' min</td>
        </tr>')

  # Clicking on the "Create a new game" button redirects to the creation page.
  $('button#createGame').click () ->
    window.location = '/create'

  # Expand SPARKETS' name when the ? is clicked.
  $('header h1:nth-child(2)').click (event) ->

    # It's a one time thing.
    $(this).unbind('hover')
    $(this).fadeOut(300, () =>
      $(this).remove()
    )

    # Store each title fragment (SPA|ceships |R|umble using Websoc|KETS).
    fragments = []
    fragments.push $(e) for e in $('*', $('header h1:first-child'))

    leftPos = [fragments[0].position().left]
    for i in [1...fragments.length]

      f = fragments[i]
      id = f.attr('id')
      num = parseInt(id.substr(id.length-1))

      # Compute the x position of each fragment for when the title is expanded.
      leftPos.push leftPos[i-1] + fragments[i-1].width()

      # Slide the SPA|R|KETS fragments to the right.
      if num % 2 is 1
        f.animate({left: (leftPos[i]-f.position().left)+'px'}, 300, 'swing')
      # Place the other fragments and make them appear.
      else
        f.css('left', leftPos[i])
        f.animate({opacity: 0.3}, 500)
