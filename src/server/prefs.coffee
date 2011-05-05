# Server constants.

exports.ship =
	dirInc: 0.1						  # Rotation increase at input update.
	speed: 0.3						  # Velocity increase at input update
	frictionDecay: 0.97			  # Inertia decay at ship update.
	minFirepower: 1.3				  # Lowest initial bullet speed.
	maxFirepower: 3				  # Highest initial bullet speed.
	cannonCooldown: 20			  # Number of frames to wait before firing again.
	maxExploFrame: 50				  # Duration of explosion animation in frames.
	enableGravity: false			  # If true, planets gravity affect ships.

exports.server =
	timestep: 20					  # ms between two a server update.
	maxBullets: 10					  # Max number of bullets updated by the server
		                          # Oldest bullets are simply discarded.
	mapSize:							  # Size of the real map (duh).
		w: 2000
		h: 2000
	planetsCount: 30				  # Number of planets on the map.


exports.mine =
	modelRadius: 5						# Drawing size on client.
	detectionRadius: 50				# Sensibility radius.
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
