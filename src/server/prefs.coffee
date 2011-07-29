utils = require '../utils'
BonusBoost = require './bonusBoost'
BonusShield = require './bonusShield'
BonusMine = require './bonusMine'
BonusTracker = require './bonusTracker'
BonusStealth = require './bonusStealth'
BonusEMP = require './bonusEMP'

class ServerPreferences
	constructor: (prefs = {}) ->
		# Override default values by those provided in `prefs'.
		utils.safeDeepMerge(prefs, @)

	# HTTP server port.
	port: 12345

	# Port of the web REPL.
	replPort: 54321

	log: ['error', 'warn', 'info', 'debug']

	# Socket.io options.
	io:
		# Allowed transports.
		# Only WebSocket and FlashSocket are fast and stable enough for Spacewar.
		transports: ['websocket', 'flashsocket']

		# Detail of log output: error (0), warn, info, debug (3)
		logLevel: 2

class GamePreferences
	constructor: (prefs = {}) ->
		# Override default values by those provided in `prefs'.
		utils.safeDeepMerge(prefs, @)

	# Debug-related preferences.
	debug:
		# Should send object hit boxes to clients.
		sendHitBoxes: no

	# ms between two server updates.
	timestep: 20

	# Duration of the game in minutes.
	duration: 5

	# Size of the real map.
	mapSize: 2000

	# The map is divided into a grid of width*height cells.
	# Colliding objects are checked only in the same cell.
	grid:
		width: 10
		height: 10

	ship:
		states:
			'spawned':
				next: 'alive'
				countdown: 1500
			'alive':
				next: 'dead'
				countdown: null
			'dead':
				next: 'spawned'
				countdown: null

		# Radius of hit circle.
		boundingRadius: 9

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

		# Gravity attraction factor, if gravity is enabled.
		gravityPull: 20

		# Maximum distance from which another ship can be targeted.
		maxTargetingDistance: 500

		# Successive fields of view used to target enemy ships.
		targetingFOVs: [30, 60, 90, 180]

	bot:
		# Number of bots on server.
		count: 0

		# Default parameters for bots.
		defaultPersona:
			# https://secure.wikimedia.org/wikipedia/en/wiki/List_of_fictional_robots_and_androids
			name: ['Tik-Tok 1', 'R.U.R 2', 'Alpha-63', 'C-4PO', 'R2D5',
				'T-600', 'Bending Unit 27', 'Hal 9008', 'No-No', 'Mall-E',
				'HK-47', 'Ash', 'Bishop', 'C-21', 'R.O.B', 'SLaDOG']

			# Distance threshold to begin firing at a target.
			acquireDistance: [400, 500]

			# Distance threshold to begin chasing an acquired target.
			chaseDistance: [200, 500]

			# Threshold at which to fire.
			firePower: [2.5, 3]

			# Angle with target at which to fire (radians).
			fireSight: [.2, Math.PI/4]

			# Angle with target at which to fire when stealthed (radians).
			fireSightStealthed: [Math.PI/16, Math.PI/8]

			# Negative gravity from planets when seeking.
			seekPlanetAvoid: [-500, -50]

			# Negative gravity from mines when seeking.
			seekMineAvoid: [-1000, -500]

			# Negative gravity from bullets when seeking.
			seekBulletAvoid: [-2000, -500]

			# Negative gravity from planets when chasing.
			chasePlanetAvoid: [-200, 0]

			# Negative gravity from mines when chasing.
			chaseMineAvoid: [-500, 0]

			# Negative gravity from bullets when chasing.
			chaseBulletAvoid: [-500, 0]

			# Distance threshold to go grab a bonus when seeking.
			grabBonusDistance: [200, 400]

			# Probability, for each state, of using each bonus.
			# Defaults to zero when no correspondin parameter is present.
			# Probability is checked at every update.
			acquireShieldUse: [.005, .05]
			acquireStealthUse: [.005, .05]
			acquireEMPUse: [.005, .05]

			chaseMineUse: [.001, .01]
			chaseShieldUse: [.001, .01]
			chaseBoostUse: [.01, 1]
			chaseTrackerUse: [.001, .01]
			chaseStealthUse: [.01, 1]
			chaseEMPUse: [.005, .01]

		# Non aggressive, used for tests.
		cameoPersona:
			name: 'Cameo'

			acquireDistance: 0
			chaseDistance: 0

			firePower: 3
			fireSight: .2

			seekPlanetAvoid: -500
			seekMineAvoid: -2000
			seekBulletAvoid: -2000

			chasePlanetAvoid: 0
			chaseMineAvoid: 0
			chaseBulletAvoid: 0

		# Killing machine, easy to crash into planets.
		boskoopPersona:
			name: 'Boskoop'

			acquireDistance: 500
			chaseDistance: 200

			firePower: 3
			fireSight: .2

			seekPlanetAvoid: -20
			seekMineAvoid: -200
			seekBulletAvoid: -200

			chasePlanetAvoid: 0
			chaseMineAvoid: 0
			chaseBulletAvoid: 0

		# Smarter navigation, reduced accuracy.
		ladyPinkPersona:
			name: 'Lady Pink'

			acquireDistance: 500
			chaseDistance: 500

			firePower: 3
			fireSight: .2

			seekPlanetAvoid: -50
			seekMineAvoid: -1000
			seekBulletAvoid: -2000

			chasePlanetAvoid: -100
			chaseMineAvoid: -200
			chaseBulletAvoid: -200

	planet:
		# Colors.
		color: [209, 29, 61]
		moonColor: [190, 70, 80]

		# Density of planets on the map in [0,1].
		# Satellites don't count here.
		density: .35

		# No planet smaller or larger than this.
		minForce: 30
		maxForce: 120

		# Probability of adding a satellite to each planet.
		satelliteChance: .2

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

	bullet:
		# Radius of hit circle.
		boundingRadius: 2

		# Gravity pull factor.
		gravityPull: 200

		# Shield repulsive force.
		shieldPull: -500

		# Bullet points to keep on server.
		tailLength: 15

		# Gap to leave in the hit line.
		checkWidth: 4

	shield:
		# Size of shield around ship.
		radius: 25

		# Gravity push factor for ships.
		shipPush: -200

		# Distance at which ships are affected by the gravity push.
		shipAffectDistance: 40

		states:
			'active':
				countdown: 5000
				next: 'dead'

			'dead':
				countdown: null
				next: null

	mine:

		# Sensibility radius.
		minDetectionRadius: 30
		maxDetectionRadius: 50

		# Speed of wave.
		waveSpeed: 0.5

		# Detonation radius.
		explosionRadius: 80

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

	tracker:

		boundingRadius: 5
		speed: 0.55
		frictionDecay: 0.95
		turnSpeed: 20

		states:
			'deploying':
				countdown: 700 				# Time (ms) before activation.
				next: 'tracking'
			'tracking':
				countdown: null
				next: 'exploding'
			'dead':
				countdown: null
				next: null

	bonus:
		states:
			'incoming':
				countdown: 2000
				next: 'available'
			'available':
				countdown: null
				next: 'claimed'
			'claimed':
				countdown: null
				next: null
			'dead':
				countdown: null
				next: null

		# ms before a bonus drop.
		waitTime: 5000

		# Number of allowed simultaneous bonuses.
		maxCount: 10

		# Type and weight of allowed bonuses.
		# Heavier bonuses spawn more often.
		bonusType:
			mine:
				class: BonusMine
				weight: 1
			tracker:
				class: BonusTracker
				weight: 1
			boost:
				class: BonusBoost
				weight: 1
			EMP:
				class: BonusEMP
				weight: 1
			shield:
				class: BonusShield
				weight: 1000
			stealth:
				class: BonusStealth
				weight: 1

		# Radius of hit circle.
		boundingRadius: 10

		# Drawing size on client.
		modelSize: 20

		# Inertia decay at update.
		frictionDecay: 0.97

		mine:
			# Number of held mines.
			mineCount: 2

		boost:
			# Initial speed multiplier.
			boostFactor: 2

			# Duration of initial boost.
			boostDuration: 1500

			# Decrease boost factor in decay state.
			boostDecay: 0.02

		EMP:
			effectRadius: 500

			# Duration of drunk side effect in ms.
			drunkDuration: 3000

		stealth:
			# Duration of invisiblity in ms.
			duration: 5000

exports.ServerPreferences = ServerPreferences
exports.GamePreferences = GamePreferences
