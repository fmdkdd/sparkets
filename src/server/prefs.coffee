BonusBoost = require './bonusBoost'
BonusMine = require './bonusMine'
BonusEMP = require './bonusEMP'
BonusDrunk = require './bonusDrunk'

# Server constants.

exports.ship =
	# Radius of hit circle.
	hitRadius: 9

	# Rotation increase at input update.
	dirInc: 0.12

	# Velocity increase at input update
	speed: 0.3

	# Inertia decay at ship update.
	frictionDecay: 0.97

	# Lowest initial bullet speed.
	minFirepower: 1.3

	# Increase in firepower at each update.
	firepowerInc: 0.1

	# Highest initial bullet speed.
	maxFirepower: 3

	# Number of frames to wait before firing again.
	cannonCooldown: 20

	# Duration of explosion animation in frames.
	maxExploFrame: 50

	# If true, planets gravity affect ships.
	enableGravity: false

exports.server =
	# HTTP server port.
	port: 12345

	# Port of the web REPL.
	replPort: 54321

	# ms between two server updates.
	timestep: 20

	# Size of the real map (duh).
	mapSize:
		w: 2000
		h: 2000

	# The map is divided into a grid of width*height cells.
	# Colliding objects are checked only in the same cell.
	grid:
		width: 10
		height: 10

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
	# ms before a bonus drop.
	waitTime: 30000

	# Number of allowed simultaneous bonuses.
	maxCount: 5

	# Type and weight of allowed bonuses.
	# Heavier bonuses spawn more often.
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

	# Radius of hit circle.
	hitRadius: 10

	# Drawing size on client.
	modelSize: 20

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
	# Number of held mines.
	mineCount: 2

exports.bonus.boost =
	# Initial speed multiplier.
	boostFactor: 2

	# Duration of initial boost.
	boostDuration: 1500

	# Decrease boost factor in decay state.
	boostDecay: 0.02

exports.bonus.emp =
	# Initial negative force.
	initialForce: 5

	# Force increase at each update.
	forceIncrease: .6

	# Max force of the EMP.
	maxForce: 100

exports.bonus.drunk =
	# Duration of drunk effect in ms.
	duration: 3000
