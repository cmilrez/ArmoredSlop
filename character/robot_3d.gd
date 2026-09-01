class_name Robot3D extends Character3D

enum {GROUNDED, AIRBORNE, BOOST, DASH, LANDING, MELEE, SHOOT_STANCE, SUPERBOOST, DEATH}
enum {IDLE, NORMAL, MULTI_LOCK, CHARGED}

@onready var anim_tree: RobotAnimator = $AnimationTree
@onready var tracker: Tracker3D = %Tracker3D
@onready var timer: Timer = $Timer

@export var data: RobotData = null
var unit_lock_time := [0.0, 0.0, 0.0, 0.0]
var unit_action_state: Array[int] = [IDLE, IDLE, IDLE, IDLE]
var state: int = GROUNDED:
	set(value):
		if not state == value:
			state = value
			#_debug_print_state()
			_state_start()
var tank_legs := false:
	set(value):
		tank_legs = value
		%LookAtTorso.use_angle_limitation = not tank_legs

# values controlled by the user
var enable_look_at := true
var move_up := false
var superboost := false
var boost := false
var angle_y := 0.0

# values controlled by the state
var _update_direction := true
var _enable_units := false
var _add_gravity := true
var _boosting := false

func _debug_print_state():
	var state_str = ''
	match state:
		GROUNDED:     state_str = 'GROUNDED'
		AIRBORNE:     state_str = 'AIRBORNE'
		BOOST:        state_str = 'BOOST'
		DASH:         state_str = 'DASH'
		LANDING:      state_str = 'LANDING'
		MELEE:        state_str = 'MELEE'
		SHOOT_STANCE: state_str = 'SHOOT_STANCE'
		SUPERBOOST:   state_str = 'SUPERBOOST'
		DEATH:        state_str = 'DEATH'
	prints(Time.get_time_string_from_system(), state_str)

func _physics_process(delta):
	if move_direction and speed:
		accelerate(move_direction, speed, 10.0)
	if _add_gravity:
		velocity += get_gravity() * delta * 6.0
	push_rigid_body_3d()
	do_friction(4.0)
	#velocity = Vector3.ZERO
	move_and_slide()
	_state_process(delta)

func change_direction(new_dir: Vector3) -> void:
	if _update_direction:
		move_direction = new_dir

func reload_unit(id: int) -> void:
	if _enable_units:
		if id > 1: # only reload arm units
			return
		var unit = weapons.get(id)
		if unit:
			unit.reload(true)

func activate_unit(id: int, targets: Array[Character3D] = []) -> void:
	var unit = weapons.get(id)
	if not unit:
		return
	if _enable_units:
		if unit.recoil and unit.can_use:
			if unit is MeleeWeapon3D:
				state = MELEE
			else:
				state = SHOOT_STANCE
				_toggle_arm_look_at(id == 0, id == 1)
				get_tree().create_timer(0.5).timeout.connect(_activate_state_weapon.bind(id))
			return
		if unit is ProjectileWeapon3D:
			if unit_lock_time[id] >= get_unit_lock_duration(id):
				if targets.is_empty():
					targets.append(tracker.target)
			else:
				targets.clear()
		unit.activate(targets, tracker.position)
	elif state == SHOOT_STANCE:
		if id > 1: # use two shoulder units at the same time
			if unit.recoil and unit.can_use:
				timer.start(1.0) # timeout
				get_tree().create_timer(0.5).timeout.connect(_activate_state_weapon.bind(id))

func get_unit_lock_duration(id: int) -> float:
	var unit = weapons.get(id)
	var duration = 0.0
	if unit.param.lock_count > 1:
		duration = unit.param.lock_duration - data.lock_on.multi_lock_reduction
	else:
		duration = unit.param.lock_duration - data.lock_on.single_lock_reduction
	return duration

func set_weapons(nodes: Array[Weapon3D]) -> void:
	weapons.clear()
	weapons = nodes.duplicate()
	var path = get_path()
	for weapon in weapons:
		if weapon:
			weapon.set_dmg_source(path)

func _state_start() -> void:
	match state:
		LANDING:
			_toggle_arm_look_at(false)
			timer.start(0.5) # timeout
		MELEE:
			_toggle_arm_look_at(false)
			if tracker.is_target_valid():
				timer.start(1.0) # timeout
			else:
				timer.start(0.5) # timeout
			timer.timeout.connect(anim_tree.start_melee_attack, CONNECT_ONE_SHOT)
			tracker.lock_target = true
			if weapons[1] is MeleeWeapon3D:
				weapons[1].activate()
		DASH:
			timer.start(data.booster.dash_duration)
		SHOOT_STANCE:
			timer.start(1.0) # timeout
			tracker.lock_target = true
		_:
			tracker.lock_target = false

func _state_process(delta: float) -> void:
	var rot_weight = exp(-5.0 * delta) if tank_legs else exp(-10.0 * delta)
	match state:
		GROUNDED:
			_update_direction = true
			_enable_units = true
			_add_gravity = true
			_boosting = false
			speed = data.legs.speed
			_toggle_look_at(true)
			_toggle_arm_look_at()
			if tank_legs:
				if move_direction:
					var move_angle = Vector2(move_direction.z, move_direction.x).angle() + PI
					rotation.y = lerp_angle(move_angle, rotation.y, rot_weight)
			else:
				rotation.y = lerp_angle(angle_y, rotation.y, rot_weight)
			if superboost:
				state = SUPERBOOST
				return
			if is_on_floor():
				if move_up:
					state = AIRBORNE # TODO maybe state = JUMP ?
					velocity.y = data.legs.jump_height
					return
				if boost and timer.is_stopped():
					if move_direction:
						state = DASH
			else:
				state = AIRBORNE
		AIRBORNE:
			_update_direction = true
			_enable_units = true
			_add_gravity = true
			_boosting = true
			speed = data.legs.speed + (data.booster.power / 1.5)
			_toggle_look_at(true)
			_toggle_arm_look_at()
			rotation.y = lerp_angle(angle_y, rotation.y, rot_weight)
			if superboost:
				state = SUPERBOOST
				return
			if is_on_floor():
				if boost:
					state = BOOST
				else:
					state = GROUNDED
					_boosting = false
				return
			if move_up:
				accelerate_up(30.0, data.booster.upward_power)
		BOOST:
			_update_direction = true
			_enable_units = true
			_add_gravity = true
			_boosting = true
			speed = data.legs.speed + data.booster.power
			_toggle_look_at(true)
			_toggle_arm_look_at()
			if tank_legs:
				if move_direction:
					var move_angle = Vector2(move_direction.z, move_direction.x).angle() + PI
					rotation.y = lerp_angle(move_angle, rotation.y, rot_weight)
			else:
				rotation.y = lerp_angle(angle_y, rotation.y, rot_weight)
			if superboost:
				state = SUPERBOOST
				return
			if is_on_floor():
				if move_up:
					state = AIRBORNE
					velocity.y = data.legs.jump_height
					return
				if boost and move_direction:
					timer.start(0.5) # brake timer
					return
				if timer.is_stopped():
					timer.start(data.booster.dash_cooldown)
					state = GROUNDED
			else:
				state = AIRBORNE
		DASH:
			_update_direction = false
			_enable_units = true
			_add_gravity = true
			_boosting = true
			speed = data.legs.speed + data.booster.dash_power
			_toggle_look_at(true)
			_toggle_arm_look_at()
			if not move_direction:
				move_direction = -basis.z
			if timer.is_stopped():
				if is_on_floor():
					if move_up:
						velocity.y = data.legs.jump_height
						state = AIRBORNE
					else:
						state = BOOST
				else:
					state = AIRBORNE
		LANDING:
			_update_direction = false
			_enable_units = false
			_add_gravity = true
			_boosting = false
			speed = 0.0
			move_direction = Vector3.ZERO
			_toggle_look_at(false)
			if not is_on_floor():
				timer.stop()
				state = AIRBORNE
				return
			if timer.is_stopped():
				state = GROUNDED
		MELEE:
			_update_direction = false
			_enable_units = false
			_add_gravity = false
			_boosting = true
			if timer.is_stopped():
				speed = data.booster.power
			else:
				speed = data.legs.speed + data.booster.power
			%LookAtLegBase.active = true
			%LookAtTorso.active = false
			if tracker.is_target_valid():
				var target_pos = tracker.position
				var distance = lock_distance_to(target_pos)
				if distance < 16.0 and not timer.is_stopped():
					timer.stop()
					timer.timeout.emit()
				move_direction = lock_direction_to(target_pos)
				var move_angle = Vector2(move_direction.z, move_direction.x).angle() + PI
				rotation.y = lerp_angle(move_angle, rotation.y, rot_weight)
			else:
				move_direction = -global_basis.z
				velocity.y = lerpf(0.0, velocity.y, exp(-delta))
		SHOOT_STANCE:
			_update_direction = true
			_enable_units = false
			_add_gravity = true
			_boosting = not is_on_floor()
			_toggle_look_at(true)
			if move_up:
				accelerate_up(30.0, data.booster.upward_power)
			if tank_legs:
				if is_on_floor():
					speed = data.legs.speed
					var move_angle = Vector2(move_direction.z, move_direction.x).angle() + PI
					rotation.y = lerp_angle(move_angle, rotation.y, rot_weight)
				else:
					speed = data.legs.speed * 0.8
					var dir = tracker.position - position
					var angle = Vector2(dir.z, dir.x).angle() + PI
					rotation.y = lerp_angle(angle, rotation.y, rot_weight)
			else:
				speed = data.legs.speed * 0.8
				var dir = tracker.position - position
				var angle = Vector2(dir.z, dir.x).angle() + PI
				rotation.y = lerp_angle(angle, rotation.y, rot_weight)
			if timer.is_stopped():
				if is_on_floor():
					if boost:
						state = BOOST
					else:
						state = GROUNDED
				else:
					state = AIRBORNE
		SUPERBOOST:
			_update_direction = false
			_enable_units = true
			_add_gravity = false
			_boosting = true
			speed = data.legs.speed + data.booster.superboost_power
			_toggle_look_at(true)
			_toggle_arm_look_at()
			var target_pos = tracker.position
			move_direction = lock_direction_to(target_pos)
			var move_angle = Vector2(move_direction.z, move_direction.x).angle() + PI
			rotation.y = lerp_angle(move_angle, rotation.y, rot_weight)
			if superboost:
				timer.start(0.5)
			if timer.is_stopped():
				if is_on_floor():
					state = GROUNDED
				else:
					state = AIRBORNE
		DEATH:
			_update_direction = false
			_enable_units = false
			_add_gravity = true
			_boosting = false
			speed = 0.0
			%LookAtLegBase.active = false
			%LookAtTorso.active = false

func _toggle_look_at(toggle: bool) -> void:
	%LookAtLegBase.active = not is_on_floor() and enable_look_at
	%LookAtTorso.active = toggle and enable_look_at

func _toggle_arm_look_at(right_arm := true, left_arm := true) -> void:
	var wp = weapons.get(0)
	var value = false
	if wp is ProjectileWeapon3D:
		value = right_arm and enable_look_at and not (wp.reloading or wp.ammo_empty)
	%LookAtArmR.toggle(value)
	wp = weapons.get(1)
	value = false
	if wp is ProjectileWeapon3D:
		value = left_arm and enable_look_at and not (wp.reloading or wp.ammo_empty)
	%LookAtArmL.toggle(value)

func _activate_state_weapon(id := 1) -> void: # default to left arm unit
	if state == DEATH:
		return
	var wp = weapons[id]
	if wp is MeleeWeapon3D:
		wp.attack()
	elif wp:
		var tar: Array[Character3D] = []
		if wp is ProjectileWeapon3D:
			if unit_lock_time[id] >= get_unit_lock_duration(id):
				tar.append(tracker.target)
		wp.activate(tar, tracker.position)

func _on_melee_finished() -> void:
	if weapons[1] is MeleeWeapon3D:
		weapons[1].cooldown()
	if is_on_floor():
		state = GROUNDED
	else:
		state = AIRBORNE

func _reset_lock_time() -> void:
	for i in range(unit_lock_time.size()):
		if unit_action_state[i] == MULTI_LOCK:
			continue
		unit_lock_time[i] = 0.0

func _on_animation_toggled_melee_hurtbox(value: bool) -> void:
	if weapons[1] is MeleeWeapon3D:
		weapons[1].toggle_hurtbox(value)

func _on_builder_body_built(nodes) -> void:
	tank_legs = data.legs.leg_type == LegsData.Type.TANK
