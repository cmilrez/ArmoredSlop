extends Node

enum {WANDER, CHASE, DEATH}

@onready var timer = $Timer

@export var character: Character = null
@export var anim_tree: AnimationTree = null
@export var look_at_mod: LookAtModifier3D = null
var home_position := Vector3.ZERO
var state := WANDER:
	set(value):
		if not state == value:
			state = value
			timer.start(1.0)

func _ready():
	anim_tree.active = true
	look_at_mod.active = true
	set_deferred(&'home_position', character.global_position)

func _process(delta):
	if not character.alive:
		state = DEATH
		return
	if character.targeting.target:
		state = CHASE
	else:
		state = WANDER

func _physics_process(delta):
	var move_direction := Vector3.ZERO
	match state:
		WANDER:
			look_at_mod.active = false
			if character.hor_distance(home_position) > 100.0:
				var direction_to_home = character.hor_direction(home_position)
				move_direction = direction_to_home
			if timer.is_stopped():
				var rand := randf_range(-1.0, 1.0)
				move_direction = Vector3.FORWARD.rotated(Vector3.UP, rand * PI)
				timer.start(maxf(5.0, 15.0 * randf()))
		CHASE:
			look_at_mod.active = true
			var distance = character.hor_distance(character.targeting.global_position)
			var direction = character.hor_direction(character.targeting.global_position)
			if distance < 30.0:
				move_direction = -direction
			elif distance < 60.0:
				var side = -character.global_basis.x.dot(direction)
				move_direction = direction.rotated(Vector3.UP, signf(side) * PI/2.0)
			else:
				move_direction = direction
			if timer.is_stopped():
				character.weapons[0].activate(character.targeting)
				timer.start(maxf(3.0, 6.0 * randf()))
		DEATH:
			look_at_mod.active = false
			character.lock_on_marker.hide()
			character.velocity.x = 0.0
			character.velocity.z = 0.0
	var root_motion = character.quaternion * anim_tree.get_root_motion_position() / delta
	character.velocity.x = root_motion.x
	character.velocity.z = root_motion.z
	character.velocity += character.get_gravity() * delta * 6.0
	
	var angle = character.global_basis.z.signed_angle_to(move_direction, Vector3.UP) if move_direction else 0.0
	anim_tree.set('parameters/Default/Move/blend_position', Vector2.UP)
	if character.targeting.target:
		anim_tree.set('parameters/Default/MoveSpeed/scale', 3.0)
	else:
		anim_tree.set('parameters/Default/MoveSpeed/scale', 1.0)
		if angle > Global.QUARTER_PI:
			anim_tree.set('parameters/Default/Move/blend_position', Vector2.LEFT)
		elif angle < -Global.QUARTER_PI:
			anim_tree.set('parameters/Default/Move/blend_position', Vector2.RIGHT)
	character.quaternion = character.quaternion * anim_tree.get_root_motion_rotation()
	character.rotate_y(signf(angle) * minf(absf(angle), delta))
