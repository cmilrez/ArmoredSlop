extends Robot

@export var camera: PlayerCamera = null

func _ready():
	weapons.resize(4)

func _process(delta):
	var input = Input.get_vector('move_left', 'move_right', 'move_forward', 'move_backward')
	change_direction(Vector3(input.x, 0.0, input.y).rotated(Vector3.UP, camera.get_arm_rotation()))
	move_up = Input.is_action_pressed('move_up')
	boost = Input.is_action_pressed('boost')
	angle_y = camera.get_arm_rotation()
	if _enable_units:
		activate_units()
	%LookAtLegBase.active = not is_on_floor()

func activate_units():
	if weapons.get(0):
		if Input.is_action_pressed('reload'):
			if Input.is_action_just_pressed('arm_unit_right'):
				weapons[0].reload(true)
		if Input.is_action_pressed('arm_unit_right'):
			if weapons[0].recoil and weapons[0].can_use:
				state_weapon_id = 0
				return
			weapons[0].activate(targeting)
	if weapons.get(1):
		if Input.is_action_pressed('reload'):
			if Input.is_action_just_pressed('arm_unit_left'):
				weapons[1].reload(true)
		if Input.is_action_pressed('arm_unit_left'):
			if weapons[1].recoil and weapons[1].can_use:
				state_weapon_id = 1
				return
			weapons[1].activate(targeting)
	if weapons.get(2):
		if Input.is_action_pressed('back_unit_right'):
			if weapons[2].recoil and weapons[2].can_use:
				state_weapon_id = 2
				return
			weapons[2].activate(targeting)
	if weapons.get(3):
		if Input.is_action_pressed('back_unit_left'):
			if weapons[3].recoil and weapons[3].can_use:
				state_weapon_id = 3
				return
			weapons[3].activate(targeting)

func _on_builder_body_built(nodes):
	tank_legs = data.legs.leg_type == LegsData.Type.TANK
