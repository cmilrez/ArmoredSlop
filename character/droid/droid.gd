extends NPC

enum {WANDER, CHASE, DEATH}

@onready var timer = $Timer

@export var anim_tree: AnimationTree = null
@export var look_at_mod: LookAtModifier3D = null
var home_position := Vector3.ZERO
var state := WANDER:
	set(value):
		if not state == value:
			state = value
			timer.start(1.0)

func _ready():
	super._ready()
	anim_tree.active = true
	look_at_mod.active = true
	timer.one_shot = true
	set_deferred(&'home_position', global_position)

func _process(delta):
	if not alive:
		state = DEATH
		return
	if targeting.target:
		state = CHASE
	else:
		state = WANDER

func _physics_process(delta):
	var move_direction := Vector3.ZERO
	match state:
		WANDER:
			look_at_mod.active = false
			if hor_distance(home_position) > 100.0:
				var direction_to_home = hor_direction(home_position)
				move_direction = direction_to_home
			if timer.is_stopped():
				var rand := randf_range(-1.0, 1.0)
				move_direction = Vector3.FORWARD.rotated(Vector3.UP, rand * PI)
				timer.start(maxf(5.0, 15.0 * randf()))
		CHASE:
			look_at_mod.active = true
			var distance = hor_distance(targeting.global_position)
			var direction = hor_direction(targeting.global_position)
			if distance < 30.0:
				move_direction = -direction
			elif distance < 60.0:
				var side = -global_basis.x.dot(direction)
				move_direction = direction.rotated(Vector3.UP, signf(side) * PI/2.0)
			else:
				move_direction = direction
			if timer.is_stopped():
				weapons[0].activate(targeting)
				timer.start(maxf(3.0, 6.0 * randf()))
		DEATH:
			look_at_mod.active = false
			lock_on_marker.hide()
			velocity.x = 0.0
			velocity.z = 0.0
	
	var angle = basis.z.signed_angle_to(move_direction, Vector3.UP) if move_direction else 0.0
	anim_tree.set('parameters/Default/Move/blend_position', Vector2.UP)
	if targeting.target:
		anim_tree.set('parameters/Default/MoveSpeed/scale', 3.0)
	else:
		anim_tree.set('parameters/Default/MoveSpeed/scale', 1.0)
		if angle > Global.QUARTER_PI:
			anim_tree.set('parameters/Default/Move/blend_position', Vector2.LEFT)
		elif angle < -Global.QUARTER_PI:
			anim_tree.set('parameters/Default/Move/blend_position', Vector2.RIGHT)
	quaternion = quaternion * anim_tree.get_root_motion_rotation()
	if angle:
		rotate_y(signf(angle) * minf(absf(angle), delta))
	
	var root_motion = quaternion * anim_tree.get_root_motion_position() / delta
	velocity.x = root_motion.x
	velocity.z = root_motion.z
	velocity += get_gravity() * delta * 6.0
	
	for i in get_slide_collision_count():
		Global.push_rigid_body_3d(get_slide_collision(i), velocity, mass)
	move_and_slide()
