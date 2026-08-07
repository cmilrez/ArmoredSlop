extends Robot

const unit_actions = [&'arm_unit_right', &'arm_unit_left', &'back_unit_right', &'back_unit_left']

@export var camera: PlayerCamera = null

#func _ready():
	#pass

func _process(delta):
	var input = Input.get_vector('move_left', 'move_right', 'move_forward', 'move_backward')
	change_direction(Vector3(input.x, 0.0, input.y).rotated(Vector3.UP, camera.get_arm_rotation()))
	move_up = Input.is_action_pressed('move_up')
	boost = Input.is_action_pressed('boost')
	angle_y = camera.get_arm_rotation()
	
	var reload = Input.is_action_pressed('reload')
	for i in range(unit_actions.size()):
		if Input.is_action_pressed(unit_actions[i]):
			if reload:
				reload_unit(i)
			else:
				activate_unit(i)

func _on_builder_body_built(nodes):
	tank_legs = data.legs.leg_type == LegsData.Type.TANK
