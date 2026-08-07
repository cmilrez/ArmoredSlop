class_name Robot extends Character

enum {GROUNDED, AIRBORNE, BOOST, DASH, LANDING, MELEE, SHOOT_STANCE, SUPERBOOST, DEATH}

@onready var targeting: Targeting = %Targeting
@onready var timer: Timer = $Timer

@export var data: RobotData = null
var state_weapon_id := -1:
	set(value):
		state_weapon_id = value
		if state_weapon_id < 0:
			return
		if weapons[state_weapon_id] is MeleeWeapon:
			state = MELEE
		else:
			state = SHOOT_STANCE

var state: int = GROUNDED: set=set_state
# intent values
var enable_look_at := true
var move_up := false
var superboost := false
var boost := false
var angle_y := 0.0

# state values
var _update_direction := true
var _enable_units := false
var _add_gravity := true
var _boosting := false

var tank_legs := false:
	set(value):
		tank_legs = value
		%LookAtTorso.use_angle_limitation = not tank_legs

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
		if id > 1:
			return
		var unit = weapons.get(id)
		if unit:
			unit.reload(true)

func activate_unit(id: int) -> void:
	if _enable_units:
		var unit = weapons.get(id)
		if unit:
			if unit.recoil and unit.can_use:
				state_weapon_id = id
				return
			unit.activate(targeting)

func set_weapons(nodes: Array[Weapon]) -> void:
	weapons.clear()
	weapons = nodes.duplicate()
	var path = get_path()
	for weapon in weapons:
		if weapon:
			weapon.set_dmg_source(path)

func set_state(new_state):
	if not state == new_state:
		state = new_state
		#_debug_print_state()
		_state_start()

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

func _state_start() -> void:
	match state:
		LANDING:
			timer.start(0.5) # timeout
			_toggle_arm_look_at(false)
		MELEE:
			if targeting.target:
				timer.start(1.0) # timeout
			else:
				timer.start(0.5) # timeout
			targeting.lock_target = true
			weapons[state_weapon_id].activate(targeting)
			_toggle_arm_look_at(false)
		DASH:
			timer.start(data.booster.dash_duration)
			if not move_direction:
				move_direction = basis.z
		SHOOT_STANCE:
			timer.start(1.0) # timeout
			targeting.lock_target = true
			_toggle_arm_look_at(false)
		_:
			targeting.lock_target = false

func _state_process(delta: float) -> void:
	var rot_weight = 1.0 - pow(0.5, delta * 16.0)
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
					rotation.y = lerp_angle(rotation.y, move_angle, rot_weight / 4.0)
			else:
				rotation.y = lerp_angle(rotation.y, angle_y, rot_weight)
			if superboost:
				state = SUPERBOOST
				return
			if is_on_floor():
				if move_up:
					state = AIRBORNE # TODO maybe state = JUMP ?
					velocity.y = data.legs.jump_height
					return
				if boost and timer.is_stopped():
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
			rotation.y = lerp_angle(rotation.y, angle_y, rot_weight)
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
					rotation.y = lerp_angle(rotation.y, move_angle, rot_weight / 4.0)
			else:
				rotation.y = lerp_angle(rotation.y, angle_y, rot_weight)
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
			speed = data.legs.speed + data.booster.power
			%LookAtLegBase.active = true
			%LookAtTorso.active = false
			if targeting.target:
				var target_pos = targeting.position
				var distance = lock_distance_to(target_pos)
				if distance < 16.0:
					timer.stop()
				move_direction = lock_direction_to(target_pos)
				var move_angle = Vector2(move_direction.z, move_direction.x).angle() + PI
				rotation.y = lerp_angle(rotation.y, move_angle, rot_weight)
			else:
				move_direction = -global_basis.z
				velocity.y = lerpf(velocity.y, 0.0, delta)
			if timer.is_stopped():
				%AnimationTree.start_melee_attack()
				speed = data.booster.power
		SHOOT_STANCE:
			_enable_units = false
			_add_gravity = false
			_boosting = not is_on_floor()
			_toggle_look_at(true)
			if tank_legs:
				_update_direction = true
				speed = data.legs.speed
				velocity += get_gravity() * delta * 3.0
				if is_on_floor():
					var move_angle = Vector2(move_direction.z, move_direction.x).angle() + PI
					rotation.y = lerp_angle(rotation.y, move_angle, rot_weight / 4.0)
				else:
					var dir = targeting.position - position
					var angle = Vector2(dir.z, dir.x).angle() + PI
					rotation.y = lerp_angle(rotation.y, angle, rot_weight)
			else:
				_update_direction = false
				speed = 0.0
				velocity.y = lerpf(velocity.y, 0.0, rot_weight)
				move_direction = Vector3.ZERO
				var dir = targeting.position - position
				var angle = Vector2(dir.z, dir.x).angle() + PI
				rotation.y = lerp_angle(rotation.y, angle, rot_weight)
			if timer.time_left < 0.5:
				weapons[state_weapon_id].activate(targeting)
			if timer.is_stopped():
				_clear_state_weapon_id()
		SUPERBOOST:
			_update_direction = false
			_enable_units = true
			_add_gravity = false
			_boosting = true
			speed = data.legs.speed + data.booster.superboost_power
			_toggle_look_at(true)
			_toggle_arm_look_at()
			var target_pos = targeting.position
			move_direction = lock_direction_to(target_pos)
			var move_angle = Vector2(move_direction.z, move_direction.x).angle() + PI
			rotation.y = lerp_angle(rotation.y, move_angle, rot_weight)
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

func _toggle_arm_look_at(toggle := true) -> void:
	toggle = toggle and enable_look_at
	var wp = weapons.get(0)
	var value = toggle and not wp.reloading and wp is not MeleeWeapon if wp else false
	%LookAtArmR.toggle(value)
	wp = weapons.get(1)
	value = toggle and not wp.reloading and wp is not MeleeWeapon if wp else false
	%LookAtArmL.toggle(value)

func _activate_state_weapon() -> void:
	var wp = weapons[state_weapon_id]
	if wp is MeleeWeapon:
		wp.attack()
	else:
		wp.activate(targeting)

func _clear_state_weapon_id() -> void:
	if weapons.get(state_weapon_id) is MeleeWeapon:
		weapons[state_weapon_id].cooldown()
	state_weapon_id = -1
	if is_on_floor():
		state = GROUNDED
	else:
		state = AIRBORNE

func _on_animation_tree_toggled_melee_hurtbox(value: bool) -> void:
	if weapons[state_weapon_id] is MeleeWeapon:
		weapons[state_weapon_id].toggle_hurtbox(value)
