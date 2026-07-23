extends Robot

enum {GROUNDED, AIRBORNE, BOOST, DASH, MELEE, RECOIL, DEATH}

@onready var dash_timer = $DashTimer
@onready var brake_timer = $BrakeTimer
@onready var melee_timer = $MeleeTimer

@export var camera: PlayerCamera = null
@export var anim_tree: AnimationTree = null
var locked_target: Character = null
var state := GROUNDED: set=set_state
var input_direction := Vector2.ZERO
var move_direction := Vector3.ZERO
var speed := 50.0
var accel := 10.0
var angle_y := 0.0
var move_angle := 0.0
var disable_units := false
var read_input := true
var do_gravity := true
var tank_legs := false:
	set(value):
		tank_legs = value
		%LookAtTorso.use_angle_limitation = not tank_legs
		if tank_legs: accel = 5.0
		else: accel = 10.0

func _ready():
	pass

func _process(delta):
	if read_input:
		input_direction.x = Input.get_axis('move_left', 'move_right')
		input_direction.y = Input.get_axis('move_forward', 'move_backward')
		move_direction = Vector3(input_direction.x, 0.0, input_direction.y)
		move_direction = move_direction.rotated(Vector3.UP, camera.get_arm_rotation()).normalized()
		if move_direction:
			move_angle = Vector2(move_direction.z, move_direction.x).angle() + PI
			anim_tree.move_angle = move_angle
		anim_tree.blend_target = input_direction
		%LookAtLegBase.active = not is_on_floor()
	_activate_units()

func _physics_process(delta):
	if move_direction:
		#speed = 0.0
		accelerate(move_direction, speed, accel)
	if do_gravity:
		velocity += get_gravity() * delta * 6.0
	rotation.y = angle_y
	for i in get_slide_collision_count():
		Global.push_rigid_body_3d(get_slide_collision(i), velocity, mass)
	do_friction(4.0)
	move_and_slide()
	_state_process(delta)

func _debug_print_state():
	var state_str = ''
	match state:
		GROUNDED: state_str = 'GROUNDED'
		AIRBORNE: state_str = 'AIRBORNE'
		BOOST: state_str = 'BOOST'
		DASH: state_str = 'DASH'
		MELEE: state_str = 'MELEE'
		RECOIL: state_str = 'RECOIL'
		DEATH: state_str = 'DEATH'
	print(Time.get_time_string_from_system(), ' - ', state_str)

func set_state(new_state):
	if not state == new_state:
		state = new_state
		#_debug_print_state()
		dash_timer.stop()
		_toggle_look_at(true)
		match state:
			MELEE:
				locked_target = targeting.target
				melee_timer.start(2.0)
				_toggle_look_at(false)
			DASH:
				dash_timer.start(0.5)
				accelerate(move_direction, 200.0, 200.0)

func _state_process(delta: float):
	var weight = 1.0 - pow(0.5, delta * 16.0)
	match state:
		GROUNDED:
			read_input = true
			boosting = false
			disable_units = false
			speed = 40.0
			if tank_legs:
				if move_direction:
					angle_y = lerp_angle(angle_y, move_angle, 3.0 * delta)
			else:
				angle_y = lerp_angle(angle_y, camera.get_arm_rotation(), weight)
			if is_on_floor():
				if Input.is_action_pressed('move_up'):
					if move_direction:
						state = DASH
					else:
						state = AIRBORNE # TODO maybe state = JUMP ?
						velocity.y += 30.0
			else:
				state = AIRBORNE
		AIRBORNE:
			read_input = true
			boosting = false
			disable_units = false
			speed = 50.0
			if tank_legs:
				angle_y = lerp_angle(angle_y, camera.get_arm_rotation(), 4.0 * delta)
			else:
				angle_y = lerp_angle(angle_y, camera.get_arm_rotation(), weight)
			if is_on_floor():
				if Input.is_action_pressed('move_up'):
					state = BOOST
				else:
					state = GROUNDED
				return
			if Input.is_action_pressed('move_up'):
				accelerate_up(30.0, 10.0)
		BOOST:
			read_input = true
			boosting = true
			disable_units = false
			speed = 60.0
			if tank_legs:
				if move_direction:
					angle_y = lerp_angle(angle_y, move_angle, 3.0 * delta)
			else:
				angle_y = lerp_angle(angle_y, camera.get_arm_rotation(), weight)
			if is_on_floor():
				if Input.is_action_just_released('move_up'):
					brake_timer.start(0.5)
					return
				if Input.is_action_just_pressed('move_up'):
					state = AIRBORNE
					accelerate_up(30.0, 30.0)
					return
				if brake_timer.is_stopped():
					if not Input.is_action_pressed('move_up'):
						state = GROUNDED
			else:
				state = AIRBORNE
		DASH:
			read_input = true
			boosting = true
			disable_units = false
			speed = 60.0
			if tank_legs:
				if move_direction:
					angle_y = lerp_angle(angle_y, move_angle, 5.0 * delta)
			else:
				angle_y = lerp_angle(angle_y, camera.get_arm_rotation(), weight)
			if dash_timer.is_stopped():
				if Input.is_action_just_pressed('move_up'):
					state = AIRBORNE
					accelerate_up(30.0, 30.0)
					return
				if Input.is_action_pressed('move_up'):
					state = BOOST
				else:
					state = GROUNDED
				return
			if not is_on_floor() or Input.is_action_just_pressed('move_up'):
				state = AIRBORNE
				accelerate_up(30.0, 30.0)
		MELEE:
			read_input = false
			boosting = false
			disable_units = true
			do_gravity = false
			speed = 50.0
			if not active_melee_weapon:
				state = AIRBORNE
				do_gravity = true
				locked_target = null
				return
			if melee_timer.is_stopped():
				active_melee_weapon.attack()
				anim_tree.start_melee_attack()
				speed = 30.0
			if locked_target:
				var target_pos = locked_target.get_lock_position()
				var distance = lock_distance_to(locked_target.global_position)
				if distance < 10.0:
					melee_timer.stop()
				move_direction = lock_direction_to(target_pos)
				angle_y = Vector2(move_direction.z, move_direction.x).angle() + PI
			else:
				move_direction = -global_basis.z
				angle_y = global_rotation.y
		#RECOIL:
			#boosting = false
			#disable_units = true
			#speed = 0.0
		#DEATH:
			#boosting = false
			#disable_units = true
			#speed = 0.0

func _toggle_look_at(enabled: bool):
	%LookAtTorso.active = enabled
	%LookAtArmJointR.active = enabled
	%LookAtArmJointL.active = enabled
	%LookAtArmR.active = enabled
	%LookAtArmL.active = enabled

func _activate_units():
	if disable_units:
		return
	var size = weapons.size()
	if size > 0:
		if Input.is_action_pressed('reload'):
			if Input.is_action_just_pressed('arm_unit_right'):
				weapons[0].reload(true)
		if Input.is_action_pressed('arm_unit_right'):
			if weapons[0] is MeleeWeapon:
				if weapons[0].can_use:
					active_melee_weapon = weapons[0]
					state = MELEE
			weapons[0].activate(targeting)
	if size > 1:
		if Input.is_action_pressed('reload'):
			if Input.is_action_just_pressed('arm_unit_left'):
				weapons[1].reload(true)
		if Input.is_action_pressed('arm_unit_left'):
			if weapons[1] is MeleeWeapon:
				if weapons[1].can_use:
					active_melee_weapon = weapons[1]
					state = MELEE
			weapons[1].activate(targeting)
	if size > 2:
		if Input.is_action_pressed('back_unit_right'):
			weapons[2].activate(targeting)
	if size > 3:
		if Input.is_action_pressed('back_unit_left'):
			weapons[3].activate(targeting)

func _on_builder_body_built(nodes):
	for part in nodes:
		var p_data = part.data
		if p_data is LegsData:
			tank_legs = p_data.leg_type == LegsData.Type.TANK
			return
