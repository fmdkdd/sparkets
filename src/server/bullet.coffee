ChangingObject = require('./changingObject').ChangingObject
utils = require '../utils'

class Bullet extends ChangingObject
	constructor: (@owner, @id, @game) ->
		super()

		@watchChanges 'type'
		@watchChanges 'color'
		@watchChanges 'hitRadius'
		@watchChanges 'pos'
		@watchChanges 'points'
		@watchChanges 'lastPoints'
		@watchChanges 'serverDelete'

		@type = 'bullet'

		xdir = 10*Math.cos(@owner.dir)
		ydir = 10*Math.sin(@owner.dir)

		@power = @owner.firePower
		@pos =
			x: @owner.pos.x + xdir
			y: @owner.pos.y + ydir
		@accel =
			x: @owner.vel.x + @power*xdir
			y: @owner.vel.y + @power*ydir

		@state = 'active'
		@hitRadius = @game.prefs.bullet.hitRadius

		@color = @owner.color
		@points = [ [@pos.x, @pos.y] ]
		@lastPoints = [ [@pos.x, @pos.y] ]

	# Apply gravity from all planets, moons, and EMPs.
	gravityVector: () ->
		# Get planets, moons and EMPs.
		filter = (obj) ->
			obj.type is 'planet' or obj.type is 'moon' or obj.type is 'EMP'

		# objectsAround() will return the same object for all cells it
		# appears in. We want to compute their gravity influence only
		# once! Thus we delete duplicates.
		gravityObjs = {}
		for cellObjs in @game.objectsAround(@pos, filter)
			for id, cellObj of cellObjs.objects
				gravityObjs[id] =
					object: cellObj.object
					relativeOffset: cellObjs.relativeOffset

		# Compute object position with relative offset.
		source = (obj) ->
			x: obj.object.pos.x + obj.relativeOffset.x
			y: obj.object.pos.y + obj.relativeOffset.y

		# Pull factor for each object.
		force = ({object: obj}) =>
			if obj.type is 'EMP'
				@game.prefs.bullet.EMPPull * obj.force
			else
				@game.prefs.bullet.gravityPull * obj.force

		return @game.gravityField(@pos, gravityObjs, source, force)

	move: () ->
		return if @state isnt 'active'

		# Compute new position from acceleration and gravity of all planets.
		gvec = @gravityVector()

		@accel.x += gvec.x
		@accel.y += gvec.y

		@pos.x += @accel.x
		@pos.y += @accel.y

		@points.push [@pos.x, @pos.y]
		@lastPoints = [ [@pos.x, @pos.y] ]

		# Warp the bullet around the map.
		{w, h} = @game.prefs.mapSize
		@warp = off
		if @pos.x < 0
			@pos.x += w
			@warp = on
		if @pos.x > w
			@pos.x -= w
			@warp = on
		if @pos.y < 0
			@pos.y += h
			@warp = on
		if @pos.y > h
			@pos.y -= h
			@warp = on

		# Append the warped point again so that the line remains continuous.
		if @warp
			@points.push [@pos.x, @pos.y]
			@lastPoints.push [@pos.x, @pos.y]

		@changed 'pos'

	update: () ->
		switch @state
			# Seek and destroy.
			when 'active'
				@points.shift() if @points.length > @game.prefs.bullet.tailLength

			# No points left, disappear.
			when 'dead'
				@serverDelete = yes

	tangible: ->
		@state is 'active'

	collidesWith: ({pos: {x,y}, hitRadius}, offset = {x:0, y:0}) ->
		x += offset.x
		y += offset.y
		# Check collisions on the line between the two latest points.
		[Ax, Ay] = if @warp then @points[@points.length-3] else @points[@points.length-2]
		[Bx, By] = if @warp then @points[@points.length-2] else @points[@points.length-1]

		return utils.lineInterCircle(Ax,Ay, Bx,By, @hitRadius, x,y,hitRadius, @game.prefs.bullet.checkWidth)?

exports.Bullet = Bullet
