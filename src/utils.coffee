utils = {}

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Array and object utils.


# Return random array element.
Array.random = (array) ->
  array[Math.floor(Math.random() * array.length)]

# Return random object property.
utils.randomObjectElem = (obj) ->
  obj[ Array.random(Object.keys(obj)) ]

# From jQuery
utils.isEmptyObject = (obj) ->
  for p of obj
    return false
  return true

# Return deep copy of obj.
# XXX: Only copies object and array properties deeply. Strings are
# immutable but other types might not be while not being flagged as
# 'object' by typeof.
utils.deepCopy = (obj, src = {}) ->
  copy = src
  for name, prop of obj
    if typeof prop is 'object' and not Array.isArray(prop)
      copy[name] = utils.deepCopy(prop, {})
    else if Array.isArray(prop)
      copy[name] = utils.deepCopy(prop, [])
    else
      copy[name] = prop

  return copy

# Merge `source' properties with `target' existing properties.
# No new property is created in `target'.
utils.safeDeepMerge = (source, target) ->
  for name, val of source
    # Only merge existing properties.
    if target[name]?

      # Recurse for object properties.
      if typeof target[name] is 'object' and not Array.isArray(target[name])
        utils.safeDeepMerge(source[name], target[name])
      else
        target[name] = val

  return target

# Put all `source' properties within `target', overwriting properties
# with the same name, and recursively calls deepMerge for object properties.
utils.deepMerge = (source, target) ->
  for name, val of source
    # Recurse for objects properties.
    if typeof source[name] is 'object' and not Array.isArray(source[name])
      target[name] = {} unless target[name]?
      utils.deepMerge(source[name], target[name])
    else
      target[name] = source[name]

  return target


#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Graphic utils.


# Stroke circle.
utils.strokeCircle = (ctxt, x, y, r) ->
  ctxt.beginPath()
  ctxt.arc(x, y, r, 2*Math.PI, false)
  ctxt.stroke()

# Color utils.

utils.color = (hsl, alpha = 1.0) ->
  'hsla(' + hsl[0] + ',' + hsl[1] + '%,' + hsl[2] + '%,' + alpha + ')'

utils.randomColor = () ->
  [Math.round(Math.random()*360), Math.round(40 + Math.random()*30), Math.round(20 + Math.random()*50)]

# Capitalize word.
utils.capitalize = (word) ->
  word[0].toUpperCase() + word.substring(1)

# Downcase word.
utils.downcase = (word) ->
  word[0].toLowerCase() + word.substring(1)

# Inexact floats have to be pretty-printed. The plan is to
# convert them using toFixed(2) for 2 decimal places.
# Integers stay as they are.
utils.prettyNumber = (str) ->
  isInt = (string) ->
    parseInt(string) == parseFloat(string)

  if isInt(str)
    str
  else
    parseFloat(str).toFixed(2)


#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Math and geometry utils.


# Stupid % operator.
utils.mod = (x, n) ->
  if isNaN(x)
    x
  else if x >= 0
    x%n
  else utils.mod(x+n, n)

# Euclidean distance between two points.
utils.distance = (x1, y1, x2, y2) ->
  Math.sqrt((x1-x2)*(x1-x2) + (y1-y2)*(y1-y2))

# Vector utils.
utils.vec =

  # Give a vector from [x1,y1] to [x2,y2].
  vector: (x1, y1, x2, y2) ->
    {x: x2-x1, y: y2-y1}

  # Give a vector going from [0,0] to [x,y].
  point: (x, y) ->
    utils.vec.vector(0, 0, x, y)

  # Give the length of v.
  length: (v) ->
    utils.distance(0, 0, v.x, v.y)

  # Give the unit vector of v.
  unit: (v) ->
    l = utils.vec.length(v)
    {x: v.x/l, y: v.y/l}

  # Give the dot product of u and v.
  dot: (u, v) ->
    u.x*v.x+u.y*v.y

  # Give v scaled by a scalar.
  times: (v, k) ->
    {x: v.x*k, y: v.y*k}

  # Give the sum of u and v.
  plus: (u, v) ->
    {x: u.x+v.x, y: u.y+v.y}

  # Give the difference of u and v.
  minus: (u, v) ->
    {x: u.x-v.x, y: u.y-v.y}

  # Give the perpendicular vector of v.
  perp: (v) ->
    {x: -v.y, y: v.x}

  # Give the vector v rotated by angle a.
  rotate: (v, a) ->
    cos = Math.cos(a)
    sin = Math.sin(a)
    {x: v.x*cos - v.y*sin, y: v.x*sin + v.y*cos}

  fromPolar: (theta, l) ->
    v = utils.vec.vector(0, 0, 1, 0)
    v = utils.vec.rotate(v, theta)
    v = utils.vec.times(v, l)

  reflect: (v) ->
    # Incident angle
    if v.x is 0
      alpha = 0
    else
      alpha = Math.tan(v.y / v.x)

    # Reflected angle
    alpha = Math.PI - alpha
    length = utils.vec.length v

    # Reflected vector
    utils.vec.fromPolar(alpha, length)

# Transform a zero-width [A,B] segment to a polygon with given width.
utils.segmentToPoly = (A, B, width) ->
  # We need four points: translate [A,B] twice.
  # Once along its normal, once along its normal's opposite.
  N = utils.vec.times(utils.vec.unit(utils.vec.perp(utils.vec.minus(B, A))), width / 2)
  oN = utils.vec.times(N, -1)

  return [
    utils.vec.plus(A, N),
    utils.vec.plus(B, N),
    utils.vec.plus(B, oN),
    utils.vec.plus(A, oN) ]

# Ensure 0 <= pos.{x,y} < s.
utils.warp = (pos, s) ->
  pos.x = utils.mod(pos.x, s)
  pos.y = utils.mod(pos.y, s)
  return pos

# Transform `pos2` so that it lies in the same frame of reference as
# `pos1`.
utils.unwarp = (pos1, pos2, s) ->
  hs = s/2
  dx = pos2.x - pos1.x
  dy = pos2.y - pos1.y

  if dx < -hs then pos2.x += s
  if dx > hs then pos2.x -= s
  if dy < -hs then pos2.y += s
  if dy > hs then pos2.y -= s

  return pos2

# Normalize angle between -pi and +pi.
utils.relativeAngle = (a) ->
  a = utils.mod(a, 2*Math.PI)

  if a > Math.PI
    a - 2*Math.PI
  else if a < -Math.PI
    a + 2*Math.PI
  else
    a

# Cubic Bézier curves going from a to b with control points c and d.
# Returns a function of time in [0,1] giving a vector.
utils.cubicBezier = (a, b, c, d) ->
  return (t) ->
    u = (1 - t)
    u2 = u * u
    u3 = u2 * u
    t2 = t * t
    t3 = t2 * t

    r = utils.vec.times(a, u3)
    r = utils.vec.plus(r, utils.vec.times(c, 3 * u2 * t))
    r = utils.vec.plus(r, utils.vec.times(d, 3 * u * t2))
    r = utils.vec.plus(r, utils.vec.times(b, t3))

    return r

# Return acceleration vector from all gravity-emitting `objects',
# having center `source' and force `force'.
utils.gravityField = (pos, objects, source, force) ->
  {x: x1, y: y1} = pos

  # Apply gravity formula.
  gravity = ({x: x2, y: y2}, g) ->
    xt = x2-x1
    yt = y2-y1
    dist = xt*xt + yt*yt
    pull = g / (dist * Math.sqrt(dist))

    return {x: xt * pull, y: yt * pull}

  vx = vy = 0
  for id, obj of objects
    f = force(obj)

    unless f is 0
      pull = gravity(source(obj), f)

      # Increase field vector.
      vx += pull.x
      vy += pull.y

  return {x: vx, y: vy}

module?.exports = utils
window?.utils = utils
