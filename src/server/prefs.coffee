# Server constants.

exports.ship =
	hitRadius: 9		  # Radius of hit circle.
	dirInc: 0.12						  	# Rotation increase at input update.
	speed: 0.3						  	# Velocity increase at input update
	frictionDecay: 0.97			  # Inertia decay at ship update.
	boostFactor: 2					  # Multiplies speed when boost is active.
	boostDecay: 0.01				  # Decrease boost factor at each update.
	minFirepower: 1.3				  # Lowest initial bullet speed.
	firepowerInc: 0.1				  # Increase in firepower at each update.
	maxFirepower: 3				  	# Highest initial bullet speed.
	cannonCooldown: 20			  # Number of frames to wait before firing again.
	maxExploFrame: 50				  # Duration of explosion animation in frames.
	enableGravity: false			# If true, planets gravity affect ships.

exports.server =
	port: 12345
	timestep: 20					  	# ms between two a server update.
	maxBullets: 10					  # Max number of bullets updated by the server
		                        # Oldest bullets are simply discarded.
	mapSize:							  	# Size of the real map (duh).
		w: 2000
		h: 2000
	planetsCount: 30				  # Number of planets on the map.

	bonusWait: 30000				  # ms before a bonus drop.

exports.bullet =
	hitRadius: 2					  # Radius of hit circle.
	gravityPull: 200				  # Gravity pull factor.
	tailLength: 15					  # Bullet points to keep on server.
	checkWidth: 4					  	# Gap to leave in the hit line.

exports.mine =
	maxDetectionRadius: 50		# Sensibility radius.
	explosionRadius: 80			  # Detonation radius.
	states:
		'inactive':
			countdown: 500			  # Time (ms) before activation.
			next: 'active'
		'active':
			countdown: null
			next: 'exploding'
		'exploding':
			countdown: 500			  # Length (ms) of explosion.
			next: 'dead'
		'dead':
			countdown: null
			next: null

exports.bonus =
	hitRadius: 10					  # Radius of hit circle.
	modelSize: 20							# Drawing size on client.
	states:
		'incoming':
			countdown: 10000
			next: 'active'
		'active':
			countdown: null
			next: 'dead'
		'dead':
			countdown: null
			next: null
