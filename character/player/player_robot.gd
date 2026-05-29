class_name Player extends Character

@onready var camera = $PlayerCamera
@onready var anim_tree = $AnimationTree
@onready var state_machine = $StateMachine
@onready var health = $Health
@onready var targeting = %Targeting
@onready var robot_hud = $RobotHud

var right_arm_unit: Weapon = null
var left_arm_unit: Weapon = null
var right_back_unit: Weapon = null
var left_back_unit: Weapon = null
var legs: BodyPart = null
var torso: BodyPart = null
var arms: BodyPart = null
var head: BodyPart = null
var active_melee_unit: MeleeWeapon = null
var input_direction := Vector2.ZERO

func _ready():
	anim_tree.active = true
	build_body()
	setup_weapons()

func _physics_process(delta):
	gravity = get_gravity()
	if alive:
		input_direction.x = Input.get_axis('move_left', 'move_right')
		input_direction.y = Input.get_axis('move_forward', 'move_backward')
		move_direction = Vector3(input_direction.x, Input.get_action_strength('move_up'), input_direction.y)
		move_direction = move_direction.rotated(Vector3.UP, camera.spring_arm.rotation.y).normalized()
		for i in get_slide_collision_count():
			Global.push_rigid_body_3d(get_slide_collision(i), velocity, mass)
	update_anim_param(delta)
	move_and_slide()

func update_anim_param(delta: float):
	var weight := 1 - pow(0.5, delta * 4)
	var blend_position: Vector2 = anim_tree.get('parameters/slide/blend_position')
	blend_position = blend_position.lerp(input_direction, weight)
	anim_tree.set('parameters/airborne/blend_position', blend_position)
	anim_tree.set('parameters/slide/blend_position', blend_position)

func face_camera(delta: float):
	var rot_weight = 1 - pow(0.5, delta * 8)
	global_rotation.y = lerp_angle(rotation.y, camera.spring_arm.rotation.y, rot_weight)

func accelerate(wish_dir: Vector3, speed: float, delta: float) -> Vector3:
	var h_vel = Vector3(velocity.x, 0.0, velocity.z)
	var vel_dir = (wish_dir * speed) - h_vel
	var wish_speed = vel_dir.length()
	var acceleration = minf(wish_speed, speed * delta * 2.0)
	if is_zero_approx(wish_speed):
		return Vector3.ZERO
	return acceleration * vel_dir / wish_speed

	#var add_speed = speed - velocity.dot(wish_dir)
	#if add_speed <= 0.0:
		#return Vector3.ZERO
	#var acceleration = minf(10.0 * delta * speed, add_speed)
	#return acceleration * wish_dir

func activate_units():
	if left_arm_unit:
		if Input.is_action_pressed('reload'):
			if Input.is_action_just_pressed('arm_unit_left'):
				left_arm_unit.reload(true)
		if Input.is_action_pressed('arm_unit_left'):
			if left_arm_unit is MeleeWeapon:
				if left_arm_unit.can_use:
					active_melee_unit = left_arm_unit
			left_arm_unit.activate(targeting)
	if right_arm_unit:
		if Input.is_action_pressed('reload'):
			if Input.is_action_just_pressed('arm_unit_right'):
				right_arm_unit.reload(true)
		if Input.is_action_pressed('arm_unit_right'):
			if right_arm_unit is MeleeWeapon:
				if right_arm_unit.can_use:
					active_melee_unit = right_arm_unit
			right_arm_unit.activate(targeting)
	if right_back_unit:
		if Input.is_action_pressed('back_unit_right'):
			right_back_unit.activate(targeting)
	if left_back_unit:
		if Input.is_action_pressed('back_unit_left'):
			left_back_unit.activate(targeting)

func set_part_scene(scene: PackedScene, part_type: int):
	var rebuild = false
	match part_type:
		1:
			if not data.head_part == scene:
				rebuild = true
				data.head_part = scene
		2:
			if not data.arms_part == scene:
				rebuild = true
				data.arms_part = scene
		3:
			if not data.torso_part == scene:
				rebuild = true
				data.torso_part = scene
		4:
			if not data.legs_part == scene:
				rebuild = true
				data.legs_part = scene
	if rebuild:
		build_body()

func build_body():
	%Skeleton3D.clear_bones()
	if is_instance_valid(legs):
		legs.queue_free()
	if is_instance_valid(torso):
		torso.queue_free()
	if is_instance_valid(arms):
		arms.queue_free()
	if is_instance_valid(head):
		head.queue_free()
	legs = setup_body_part(data.legs_part)
	torso = setup_body_part(data.torso_part)
	arms = setup_body_part(data.arms_part)
	head = setup_body_part(data.head_part)
	data.defense_bullet = data.defense_bullet / 1000.0
	data.defense_energy = data.defense_energy / 1000.0
	data.defense_explosive = data.defense_explosive / 1000.0
	%Skeleton3D.set_bone_parent(%Skeleton3D.find_bone('Torso'), %Skeleton3D.find_bone('TorsoJoint'))
	%Skeleton3D.set_bone_parent(%Skeleton3D.find_bone('Shoulder.R'), %Skeleton3D.find_bone('ArmJoint.R'))
	%Skeleton3D.set_bone_parent(%Skeleton3D.find_bone('Shoulder.L'), %Skeleton3D.find_bone('ArmJoint.L'))
	%Skeleton3D.set_bone_rest(%Skeleton3D.add_bone('ArmUnit.R'), %HandSkel.get_bone_rest(%HandSkel.find_bone('ArmUnit.R')))
	%Skeleton3D.set_bone_rest(%Skeleton3D.add_bone('ArmUnit.L'), %HandSkel.get_bone_rest(%HandSkel.find_bone('ArmUnit.L')))
	%Skeleton3D.set_bone_parent(%Skeleton3D.find_bone('ArmUnit.R'), %Skeleton3D.find_bone('Hand.R'))
	%Skeleton3D.set_bone_parent(%Skeleton3D.find_bone('ArmUnit.L'), %Skeleton3D.find_bone('Hand.L'))
	%Skeleton3D.reset_bone_poses()
	#%Skeleton3D.register_skin(%Skeleton3D.create_skin_from_rest_transforms())
	%Hands.skeleton = %Skeleton3D.get_path()
	%ArmUnitR.bone_idx = %Skeleton3D.find_bone('ArmUnit.R')
	%ArmUnitL.bone_idx = %Skeleton3D.find_bone('ArmUnit.L')
	%BackUnitR.bone_idx = %Skeleton3D.find_bone('BackUnit.R')
	%BackUnitL.bone_idx = %Skeleton3D.find_bone('BackUnit.L')
	%Torso.bone_idx = %Skeleton3D.find_bone('Torso')

func setup_body_part(scene: PackedScene) -> Node:
	var part = scene.instantiate()
	data.max_hp += part.data.armor
	data.defense_bullet += part.data.defense_bullet
	data.defense_energy += part.data.defense_energy
	data.defense_explosive += part.data.defense_explosive
	if not scene == data.head_part:
		setup_skeleton(%Skeleton3D, part.data.bone_list)
	%Skeleton3D.add_child(part)
	part.skeleton = %Skeleton3D.get_path()
	return part

func setup_weapons():
	if is_instance_valid(right_arm_unit):
		right_arm_unit.queue_free()
	if is_instance_valid(left_arm_unit):
		left_arm_unit.queue_free()
	if is_instance_valid(right_back_unit):
		right_back_unit.queue_free()
	if is_instance_valid(left_back_unit):
		left_back_unit.queue_free()
	var node_path = get_path()
	if data.right_arm_part:
		right_arm_unit = data.right_arm_part.instantiate()
		%ArmUnitR.add_child(right_arm_unit)
		right_arm_unit.data.damage_data.source = node_path
		right_arm_unit.ammo_changed.connect(robot_hud.update_ammo_display.bind(0))
	if data.left_arm_part:
		left_arm_unit = data.left_arm_part.instantiate()
		%ArmUnitL.add_child(left_arm_unit)
		left_arm_unit.data.damage_data.source = node_path
		left_arm_unit.ammo_changed.connect(robot_hud.update_ammo_display.bind(1))
	if data.right_back_part:
		right_back_unit = data.right_back_part.instantiate()
		%BackUnitR.add_child(right_back_unit)
		right_back_unit.data.damage_data.source = node_path
		right_back_unit.ammo_changed.connect(robot_hud.update_ammo_display.bind(2))
	if data.left_back_part:
		left_back_unit = data.left_back_part.instantiate()
		%BackUnitL.add_child(left_back_unit)
		left_back_unit.data.damage_data.source = node_path
		left_back_unit.ammo_changed.connect(robot_hud.update_ammo_display.bind(3))

func setup_skeleton(skeleton: Skeleton3D, bone_list: Dictionary):
	for bone: String in bone_list.keys():
		var bone_id = skeleton.add_bone(bone)
		skeleton.set_bone_rest(bone_id, bone_list[bone][0]) 
		#print(bone, ' : ', skeleton.get_bone_rest(bone_id))
	for parent: String in bone_list.keys():
		var parent_id = skeleton.find_bone(parent)
		for child: String in bone_list[parent][1]:
			var child_id = skeleton.find_bone(child)
			skeleton.set_bone_parent(child_id, parent_id)

func clear_melee_unit():
	if active_melee_unit:
		active_melee_unit.cooldown()
	active_melee_unit = null

func _on_melee_attack_started():
	if active_melee_unit:
		active_melee_unit.attack()

func _on_animation_tree_toggled_melee_hurtbox(enabled):
	if active_melee_unit:
		active_melee_unit.toggle_hurtbox(enabled)
