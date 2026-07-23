extends Robot

enum {WANDER, CHASE, DEATH}

@onready var move_timer = $MoveTimer
@onready var atk_timer = $AtkTimer

@export var anim_tree: AnimationTree = null
var home_position := Vector3.ZERO
var move_direction := Vector3.ZERO
var speed := 40.0
var accel = 5.0
var angle_y := 0.0
var state := WANDER:
	set(value):
		if not state == value:
			state = value
			atk_timer.start(1.0)

func _ready():
	lock_on_marker.screen_entered.connect(func(): SignalBus.enemy_entered_screen.emit(self))
	lock_on_marker.screen_exited.connect(func(): SignalBus.enemy_exited_screen.emit(self))
	set_weapons(weapons.duplicate()) # xd
	set_deferred(&'home_position', global_position)

func _process(delta):
	%LookAtLegBase.active = false
	if not alive:
		state = DEATH
		return
	if targeting.target:
		state = CHASE
		%LookAtLegBase.active = not is_on_floor()
	else:
		state = WANDER

func _physics_process(delta):
	match state:
		WANDER:
			speed = 20.0
			_toggle_look_at(false)
			if hor_distance(home_position) > 100.0:
				var direction_to_home = hor_direction(home_position)
				move_direction = direction_to_home
			if move_timer.is_stopped():
				move_direction = Vector3.FORWARD.rotated(Vector3.UP, randf_range(-1.0, 1.0) * PI)
				move_timer.start(maxf(5.0, 15.0 * randf()))
			var hor_vel = Vector2(velocity.z, velocity.x)
			if hor_vel:
				angle_y = hor_vel.angle() + PI
		CHASE:
			speed = 40.0
			_toggle_look_at(true)
			var distance = hor_distance(targeting.global_position)
			var direction = hor_direction(targeting.global_position)
			if distance < 30.0:
				move_direction = -direction
			elif distance < 120.0:
				if move_timer.is_stopped():
					move_direction = global_basis.x.rotated(Vector3.UP, randf_range(-1.0, 1.0) * PI)
					move_timer.start(maxf(3.0, 5.0 * randf()))
			else:
				move_direction = direction
				move_timer.stop()
			angle_y = Vector2(direction.z, direction.x).angle() + PI
			if atk_timer.is_stopped():
				weapons[0].activate(targeting)
				weapons[1].activate(targeting)
				atk_timer.start(maxf(0.3, 1.0 * randf()))
		DEATH:
			_toggle_look_at(false)
			lock_on_marker.hide()
			move_direction = Vector3.ZERO
	if move_direction:
		accelerate(move_direction, speed, accel)
	velocity += get_gravity() * delta * 6.0
	var weight = 1 - pow(0.5, delta * 16.0)
	rotation.y = lerp_angle(rotation.y, angle_y, weight)
	anim_tree.blend_target = Vector2(move_direction.x, move_direction.z).rotated(rotation.y)
	for i in get_slide_collision_count():
		Global.push_rigid_body_3d(get_slide_collision(i), velocity, mass)
	do_friction(4.0)
	move_and_slide()

func _toggle_look_at(enabled: bool):
	%LookAtTorso.active = enabled
	%LookAtArmJointR.active = enabled
	%LookAtArmJointL.active = enabled
	%LookAtArmR.active = enabled
	%LookAtArmL.active = enabled
