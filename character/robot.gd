class_name Robot extends Character

enum {GROUNDED, AIRBORNE, BOOST, DASH, LANDING, MELEE, RECOIL, DEATH}

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
			state = RECOIL

var state := GROUNDED: set=set_state
# intent values
var move_up := false
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
	if move_direction:
		#speed = 0.0
		accelerate(move_direction, speed, 10.0)
	if _add_gravity:
		velocity += get_gravity() * delta * 6.0
	push_rigid_body_3d()
	do_friction(4.0)
	move_and_slide()
	_state_process(delta)

func change_direction(new_dir: Vector3) -> void:
	if _update_direction:
		move_direction = new_dir

func set_weapons(nodes: Array[Weapon]) -> void:
	weapons.clear()
	var path = get_path()
	for weapon in nodes:
		if weapon:
			weapon.set_dmg_source(path)
		weapons.append(weapon)

func set_state(new_state):
	if not state == new_state:
		state = new_state
		#_debug_print_state()
		_state_start()

func _debug_print_state():
	var state_str = ''
	match state:
		GROUNDED: state_str = 'GROUNDED'
		AIRBORNE: state_str = 'AIRBORNE'
		BOOST:    state_str = 'BOOST'
		DASH:     state_str = 'DASH'
		LANDING:  state_str = 'LANDING'
		MELEE:    state_str = 'MELEE'
		RECOIL:   state_str = 'RECOIL'
		DEATH:    state_str = 'DEATH'
	prints(Time.get_time_string_from_system(), state_str)

func _state_start() -> void:
	match state:
		LANDING:
			timer.start(0.5) # timeout
		MELEE:
			timer.start(2.0) # timeout
			_toggle_look_at(false)
		DASH:
			timer.start(data.booster.dash_duration)
			if not move_direction:
				move_direction = basis.z
		RECOIL:
			timer.start(1.0) # timeout
			targeting.lock_target = true
		_:
			targeting.lock_target = false
			_toggle_look_at(true)

func _state_process(delta: float) -> void:
	var rot_weight = 1.0 - pow(0.5, delta * 16.0)
	match state:
		GROUNDED:
			_update_direction = true
			_enable_units = true
			_add_gravity = true
			_boosting = false
			speed = data.legs.speed
			if tank_legs:
				if move_direction:
					var move_angle = Vector2(move_direction.z, move_direction.x).angle() + PI
					rotation.y = lerp_angle(rotation.y, move_angle, rot_weight / 4.0)
			else:
				rotation.y = lerp_angle(rotation.y, angle_y, rot_weight)
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
			rotation.y = lerp_angle(rotation.y, angle_y, rot_weight)
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
			if tank_legs:
				if move_direction:
					var move_angle = Vector2(move_direction.z, move_direction.x).angle() + PI
					rotation.y = lerp_angle(rotation.y, move_angle, rot_weight / 4.0)
			else:
				rotation.y = lerp_angle(rotation.y, angle_y, rot_weight)
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
			if not is_on_floor():
				state = AIRBORNE
				return
			if timer.is_stopped():
				state = GROUNDED
		MELEE:
			_update_direction = false
			_enable_units = false
			_add_gravity = false
			_boosting = true
			speed = 50.0
			if timer.is_stopped():
				weapons[state_weapon_id].attack()
				#anim_tree.start_melee_attack()
				speed = 30.0
			if targeting.target:
				var target_pos = targeting.position
				var distance = lock_distance_to(target_pos)
				if distance < 10.0:
					timer.stop()
				move_direction = lock_direction_to(target_pos)
				rotation.y = Vector2(move_direction.z, move_direction.x).angle() + PI
			else:
				move_direction = -global_basis.z
		RECOIL:
			_enable_units = false
			_add_gravity = false
			_boosting = not is_on_floor()
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
				velocity.y = 0.0
				move_direction = Vector3.ZERO
				var dir = targeting.position - position
				var angle = Vector2(dir.z, dir.x).angle() + PI
				rotation.y = lerp_angle(rotation.y, angle, rot_weight)
			if timer.time_left < 0.5:
				weapons[state_weapon_id].activate(targeting)
			if timer.is_stopped():
				_clear_state_weapon_id()
				if is_on_floor():
					state = GROUNDED
				else:
					state = AIRBORNE
				return
		DEATH:
			_update_direction = false
			_enable_units = false
			_add_gravity = true
			_boosting = false
			speed = 0.0

func _toggle_look_at(enabled: bool):
	%LookAtTorso.active = enabled
	%LookAtArmJointR.active = enabled
	%LookAtArmJointL.active = enabled
	%LookAtArmR.active = enabled
	%LookAtArmL.active = enabled

func _clear_state_weapon_id():
	if weapons[state_weapon_id] is MeleeWeapon:
		weapons[state_weapon_id].cooldown()
	state_weapon_id = -1

func _on_animation_tree_toggled_melee_hurtbox(enabled):
	if weapons[state_weapon_id] is MeleeWeapon:
		weapons[state_weapon_id].toggle_hurtbox(enabled)
