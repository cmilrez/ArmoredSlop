extends NPC3D

enum {IDLE, WANDER, SEARCHING, CHASE, DEATH}
const PARAM_MOVE_BLEND = &'parameters/Wander/blend_position'

@onready var timer = $Timer

@export var anim_tree: AnimationTree = null
@export var look_at_mod: LookAtModifier3D = null
var home_position := Vector3.ZERO
var state: int = WANDER:
	set(value):
		if not state == value:
			state = value
			_state_start()

func _ready():
	super._ready()
	anim_tree.active = true
	timer.one_shot = true
	set_deferred(&'home_position', global_position)

func _process(delta):
	if alive:
		quaternion = quaternion * anim_tree.get_root_motion_rotation()
		var root_motion = quaternion * anim_tree.get_root_motion_position()
		velocity.x = root_motion.x / delta
		velocity.z = root_motion.z / delta
	else:
		state = DEATH

func _physics_process(delta):
	velocity += get_gravity() * delta * 6.0
	
	push_rigid_body_3d()
	move_and_slide()
	_state_process(delta)

func _state_start() -> void:
	match state:
		IDLE:
			look_at_mod.active = false
			timer.stop()
		WANDER:
			look_at_mod.active = false
			timer.stop()
		SEARCHING:
			look_at_mod.active = false
			timer.start(maxf(3.0, randf() * 6.0))
		CHASE:
			look_at_mod.active = true
			timer.start(1.0)
		DEATH:
			look_at_mod.active = false
			lock_on_marker.hide()

func _state_process(delta: float) -> void:
	match state:
		IDLE:
			move_direction = Vector3.ZERO
			var weight = exp(-8.0 * delta)
			var blend = anim_tree.get(PARAM_MOVE_BLEND)
			blend = Vector2.ZERO.lerp(blend, weight)
			anim_tree.set(PARAM_MOVE_BLEND, blend)
		WANDER:
			if hor_distance(home_position) > 100.0:
				var direction_to_home = hor_direction(home_position)
				move_direction = direction_to_home
			if timer.is_stopped():
				var rand = randf()
				if rand < 0.1:
					state = SEARCHING
					return
				rand = randf_range(-1.0, 1.0)
				var rand_dir = Vector2.UP.rotated(rand * PI)
				move_direction = Vector3(rand_dir.x, 0.0, rand_dir.y)
				timer.start(maxf(5.0, 15.0 * randf()))
			var weight = exp(-8.0 * delta)
			var angle = hor_angle(move_direction)
			var blend = anim_tree.get(PARAM_MOVE_BLEND)
			if angle > Global.QUARTER_PI:
				blend = Vector2.LEFT.lerp(blend, weight)
			elif angle < -Global.QUARTER_PI:
				blend = Vector2.RIGHT.lerp(blend, weight)
			else:
				blend = Vector2.UP.lerp(blend, weight)
			anim_tree.set(PARAM_MOVE_BLEND, blend)
			if angle:
				rotate_y(signf(angle) * minf(absf(angle), delta))
			if tracker.is_target_valid():
				state = CHASE
		SEARCHING:
			move_direction = Vector3.ZERO
			if tracker.is_target_valid():
				state = CHASE
				return
			if timer.is_stopped():
				state = WANDER
		CHASE:
			if not tracker.is_target_valid():
				state = WANDER
				return
			var distance = hor_distance(tracker.position)
			var direction = hor_direction(tracker.position)
			if distance < 30.0:
				move_direction = -direction
			elif distance < 60.0:
				var side = -basis.x.dot(direction)
				var dir = Vector2(direction.z, direction.x).rotated(signf(side) * Global.HALF_PI)
				move_direction = Vector3(dir.y, 0.0, dir.x)
			else:
				move_direction = direction
			if timer.is_stopped():
				weapons[0].activate([tracker.target])
				timer.start(maxf(2.0, 5.0 * randf()))
			var angle = hor_angle(move_direction)
			if angle:
				rotate_y(signf(angle) * minf(absf(angle), 2.0 * delta))
		DEATH:
			velocity.x = 0.0
			velocity.z = 0.0
