extends Robot

enum {IDLE, ACTIVE, CHARGING}
const unit_actions = [&'arm_unit_right', &'arm_unit_left', &'back_unit_right', &'back_unit_left']

@export var camera: PlayerCamera = null
var unit_input_state: Array[int] = [IDLE, IDLE, IDLE, IDLE]
var action_hold_duration := [0.0, 0.0, 0.0, 0.0]

func _process(delta):
	super._process(delta)
	var input = Input.get_vector('move_left', 'move_right', 'move_forward', 'move_backward')
	change_direction(Vector3(input.x, 0.0, input.y).rotated(Vector3.UP, camera.get_arm_rotation()))
	move_up = Input.is_action_pressed('move_up')
	boost = Input.is_action_pressed('boost')
	angle_y = camera.get_arm_rotation()
	
	var reload = Input.is_action_pressed('reload')
	var max_lock_count = 0
	for i in range(unit_actions.size()):
		var unit = weapons[i]
		match unit_input_state[i]:
			IDLE:
				continue
			ACTIVE:
				if Input.is_action_pressed(unit_actions[i]):
					if reload:
						reload_unit(i)
						unit_input_state[i] = IDLE
					else:
						activate_unit(i)
				else:
					unit_input_state[i] = IDLE
				continue
			CHARGING:
				if reload:
					unit_input_state[i] = IDLE
					action_hold_duration[i] = 0.0
					continue
				var lock_finished = action_hold_duration[i] > unit.param.multi_lock_duration - data.lock_on.multi_duration
				if Input.is_action_pressed(unit_actions[i]):
					action_hold_duration[i] += delta
					if lock_finished:
						if unit.param.lock_count > max_lock_count:
							max_lock_count = unit.param.lock_count - 1
				elif Input.is_action_just_released(unit_actions[i]):
					unit_input_state[i] = IDLE
					action_hold_duration[i] = 0.0
					if lock_finished:
						var targets: Array[Character] = [tracker.target]
						targets.append_array(camera.multi_target_list)
						if targets.size() > unit.param.lock_count:
							targets.resize(unit.param.lock_count)
						activate_unit(i, targets)
					else:
						activate_unit(i)
				continue
	camera.multi_target_count = max_lock_count

func _unhandled_input(event):
	for i in range(unit_actions.size()):
		if event.is_action_pressed(unit_actions[i]):
			var unit = weapons[i]
			if unit is ProjectileWeapon3D and unit.param.lock_count > 1:
				unit_input_state[i] = CHARGING
			else:
				unit_input_state[i] = ACTIVE
			return
