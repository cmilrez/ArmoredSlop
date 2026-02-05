class_name Player extends Character

@onready var camera = $PlayerCamera
@onready var anim_tree = $AnimationTree
@onready var health = $Health
@onready var targeting = %Targeting

var right_arm_unit: Weapon = null
var left_arm_unit: Weapon = null
var right_back_unit: Weapon = null
var left_back_unit: Weapon = null
var anim_state_machine: AnimationNodeStateMachinePlayback = null
var input_direction := Vector2.ZERO

func _ready():
	anim_state_machine = anim_tree.get('parameters/playback')
	anim_tree.active = true
	setup_units()

func _process(delta):
	if not alive:
		return
	if left_arm_unit:
		if Input.is_action_pressed('reload'):
			if Input.is_action_just_pressed('arm_unit_left'):
				left_arm_unit.reload(true)
		if Input.is_action_pressed('arm_unit_left'):
			left_arm_unit.activate(targeting)
	if right_arm_unit:
		if Input.is_action_pressed('reload'):
			if Input.is_action_just_pressed('arm_unit_right'):
				right_arm_unit.reload(true)
		if Input.is_action_pressed('arm_unit_right'):
			right_arm_unit.activate(targeting)
	if right_back_unit:
		if Input.is_action_pressed('back_unit_right'):
			right_back_unit.activate(targeting)
	if left_back_unit:
		if Input.is_action_pressed('back_unit_left'):
			left_back_unit.activate(targeting)

func _physics_process(delta):
	gravity = get_gravity()
	if alive:
		input_direction.x = Input.get_axis('move_left', 'move_right')
		input_direction.y = Input.get_axis('move_forward', 'move_backward')
		move_direction = (Vector3(input_direction.x, Input.get_action_strength('move_up'), input_direction.y)).rotated(Vector3.UP, camera.spring_arm.rotation.y).normalized()
		var rot_weight = 1 - pow(0.5, delta * 8)
		global_rotation.y = lerp_angle(rotation.y, camera.spring_arm.rotation.y, rot_weight)
		for i in get_slide_collision_count():
			Global.push_rigid_body_3d(get_slide_collision(i), velocity, mass)
	update_anim_param(delta)
	move_and_slide()

func update_anim_param(delta: float):
	var weight := 1 - pow(0.5, delta * 4)
	var blend_position: Vector2 = anim_tree.get('parameters/slide/blend_position').lerp(input_direction, weight)
	anim_tree.set('parameters/airborne/blend_position', blend_position)
	anim_tree.set('parameters/slide/blend_position', blend_position)

func setup_units():
	const id = 0
	var node_path = get_path()
	if %ArmUnitR.get_child_count():
		right_arm_unit = %ArmUnitR.get_child(id)
		right_arm_unit.data.damage_data.source = node_path
	if %ArmUnitL.get_child_count():
		left_arm_unit = %ArmUnitL.get_child(id)
		left_arm_unit.data.damage_data.source = node_path
	if %BackUnitR.get_child_count():
		right_back_unit = %BackUnitR.get_child(id)
		right_back_unit.data.damage_data.source = node_path
	if %BackUnitL.get_child_count():
		left_back_unit = %BackUnitL.get_child(id)
		left_back_unit.data.damage_data.source = node_path
