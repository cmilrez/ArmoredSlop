extends Robot

const unit_actions = [&'arm_unit_right', &'arm_unit_left', &'back_unit_right', &'back_unit_left']
const min_multi_lock_time = 0.5 # seconds

@export var camera: PlayerCamera = null
var multi_lock_hold_time := [0.0, 0.0, 0.0, 0.0]

func _process(delta):
	var input = Input.get_vector('move_left', 'move_right', 'move_forward', 'move_backward')
	change_direction(Vector3(input.x, 0.0, input.y).rotated(Vector3.UP, camera.get_arm_rotation()))
	move_up = Input.is_action_pressed('move_up')
	boost = Input.is_action_pressed('boost')
	angle_y = camera.get_arm_rotation()
	
	var reload = Input.is_action_pressed('reload')
	var max_multi_lock_count = 0
	for i in range(unit_actions.size()):
		var unit = weapons[i]
		if unit and unit.reloading:
			unit_lock_time[i] = 0.0
		else:
			unit_lock_time[i] += delta
		match unit_action_state[i]:
			IDLE:
				continue
			NORMAL:
				var can_multi_lock = unit is ProjectileWeapon3D and unit.param.lock_count > 1
				if Input.is_action_pressed(unit_actions[i]):
					if can_multi_lock:
						multi_lock_hold_time[i] += delta
						if multi_lock_hold_time[i] > min_multi_lock_time:
							multi_lock_hold_time[i] = 0.0
							unit_lock_time[i] = 0.0
							unit_action_state[i] = MULTI_LOCK
						continue
					if reload:
						reload_unit(i)
						unit_action_state[i] = IDLE
					else:
						activate_unit(i)
				else:
					if can_multi_lock:
						activate_unit(i)
					unit_action_state[i] = IDLE
				continue
			MULTI_LOCK:
				if reload:
					unit_lock_time[i] = 0.0
					unit_action_state[i] = IDLE
					continue
				var multi_lock_finished = unit_lock_time[i] >= get_unit_lock_duration(i)
				if multi_lock_finished:
					if unit.param.lock_count > max_multi_lock_count:
						max_multi_lock_count = unit.param.lock_count - 1
				if not Input.is_action_pressed(unit_actions[i]):
					if multi_lock_finished:
						var targets: Array[Character] = [tracker.target]
						targets.append_array(camera.multi_target_list)
						if targets.size() > unit.param.lock_count:
							targets.resize(unit.param.lock_count)
						activate_unit(i, targets)
					else:
						activate_unit(i)
					unit_lock_time[i] = 0.0
					unit_action_state[i] = IDLE
				continue
			CHARGED:
				continue
	camera.multi_target_count = max_multi_lock_count

func _unhandled_input(event):
	for i in range(unit_actions.size()):
		if event.is_action_pressed(unit_actions[i]):
			unit_action_state[i] = NORMAL
			return
