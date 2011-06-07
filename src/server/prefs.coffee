BonusBoost = require './bonusBoost'
BonusMine = require './bonusMine'
BonusEMP = require './bonusEMP'
BonusDrunk = require './bonusDrunk'

# Server constants.

exports.ship =
	hitRadius: 9		  # Radius of hit circle.
	dirInc: 0.12						  	# Rotation increase at input update.
	speed: 0.3						  	# Velocity increase at input update
	frictionDecay: 0.97			  # Inertia decay at ship update.
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

	grid:
		width: 10
		height: 10

	bonusWait: 30000				  # ms before a bonus drop.
	maxBonuses: 5				  # Number of allowed simultaneous bonuses.

	replPort: 54321				  # Port of the web REPL.

exports.planet =
	# Number of planets on the map. Satellites don't count here.
	count: 30

	# No planet smaller or larger than this.
	minForce: 30
	maxForce: 120

	# Probability of adding a satellite to each planet.
	satelliteChance: .3

	# Safeguard value (can't draw planets smaller than the line width,
	# and gravity doesn't bode well with small planets)
	satelliteAbsMinForce: 10

	# Range of satellite size (factor of planet force).
	satelliteMinForce: .1
	satelliteMaxForce: .3

	# Range of gap between planet and satellite (factor of planet force).
	satelliteMinGap: .2
	satelliteMaxGap: .6

	# Range of attraction factor of satellites by planets.
	satellitePullMin: .03
	satellitePullMax: .2

exports.bullet =
	hitRadius: 2					  # Radius of hit circle.
	gravityPull: 200				  # Gravity pull factor.
	EMPPull: -500					  # EMP repulsive force.
	tailLength: 15					  # Bullet points to keep on server.
	checkWidth: 4					  	# Gap to leave in the hit line.

exports.mine =
	maxDetectionRadius: 50		# Sensibility radius.
	explosionRadius: 80			  # Detonation radius.
	states:
		'inactive':
			countdown: 100			  # Time (ms) before activation.
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
	bonusType:
		mine:
			class: BonusMine
			weight: 3
		boost:
			class: BonusBoost
			weight: 2
		EMP:
			class: BonusEMP
			weight: 1
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

exports.bonus.mine =
	mineCount: 2					  # Number of held mines.

exports.bonus.boost =
	boostFactor: 2					 # Initial speed multiplier.
	boostDuration: 1500			 # Duration of initial boost.
	boostDecay: 0.02				  # Decrease boost factor in decay state.

exports.bonus.emp =
	initialForce: 5				  # Initial negative force.
	forceIncrease: .6				  # Force increase at each update.
	maxForce: 100					  # Max force of the EMP.

exports.bonus.drunk =
	duration: 3000					  # Duration of drunk effect in ms.
