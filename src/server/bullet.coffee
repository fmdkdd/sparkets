ChangingObject = require('./changingObject').ChangingObject

class Bullet extends ChangingObject
	constructor: (@id, @game, @owner) ->
		super()

		@watchChanges 'type'
		@watchChanges 'color'
		@watchChanges 'lastPoints'
		@watchChanges 'serverDelete'
		@watchChanges 'boundingRadius'
		@watchChanges 'hitBox'

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

		@boundingRadius = @game.prefs.bullet.boundingRadius
		@hitBox =
			type: 'segments'
			points: [
				{x: @pos.x, y: @pos.y},
				{x: @pos.x, y: @pos.y}]

		@color = @owner.color
		@points = [ [@pos.x, @pos.y] ]
		@lastPoints = [ [@pos.x, @pos.y] ]

	# Apply gravity from all planets, moons, and shields.
	gravityVector: () ->
		# Get planets, moons and shields.
		filter = (obj) ->
			obj.type is 'planet' or obj.type is 'moon' or obj.type is 'shield'

		# Pull factor for each object.
		force = ({object: obj}) =>
			if obj.type is 'shield'
				if obj.ship is @owner
					0
				else
					@game.prefs.bullet.shieldPull * obj.force
			else
				@game.prefs.bullet.gravityPull * obj.force

		return @game.gravityFieldAround(@pos, filter, force)

	move: () ->
		return if @state isnt 'active'

		# Compute new position from acceleration and gravity of all planets.
		gvec = @gravityVector()

		@accel.x += gvec.x
		@accel.y += gvec.y

		@pos.x += @accel.x
		@pos.y += @accel.y

		@points.push [@pos.x, @pos.y]
		@lastPoints = [[@pos.x, @pos.y]]

		# Warp the bullet around the map.
		s = @game.prefs.mapSize
		@warp = off
		if @pos.x < 0
			@pos.x += s
			@warp = on
		if @pos.x > s
			@pos.x -= s
			@warp = on
		if @pos.y < 0
			@pos.y += s
			@warp = on
		if @pos.y > s
			@pos.y -= s
			@warp = on

		# Append the warped point again so that the line remains continuous.
		if @warp
			@points.push [@pos.x, @pos.y]
			@lastPoints.push [@pos.x, @pos.y]

		# Update hitbox.
		if @warp
			A = @points[@points.length-3]
			B = @points[@points.length-2]
		else
			A = @points[@points.length-2]
			B = @points[@points.length-1]
		@hitBox.points[0].x = A[0]
		@hitBox.points[0].y = A[1]
		@hitBox.points[1].x = B[0]
		@hitBox.points[1].y = B[1]
		@changed 'hitBox'

	update: () ->
		switch @state
			# Seek and destroy.
			when 'active'
				@points.shift() if @points.length > @game.prefs.bullet.tailLength

			# No points left, disappear.
			when 'dead'
				@serverDelete = yes

	explode: () ->
		@state = 'dead'

	tangible: ->
		@state is 'active'

exports.Bullet = Bullet
