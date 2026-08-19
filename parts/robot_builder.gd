@tool
class_name RobotBuilder extends Node

signal body_built(nodes: Array[BodyPart])
signal weapons_built(nodes: Array[Weapon3D])

@export_tool_button('BUILD BODY', 'BuildCSharp') var build1 = _build_body
@export_tool_button('BUILD WEAPONS', 'BuildCSharp') var build2 = _build_weapons
@export var make_owner := false
@export var data: RobotData = null
@export var weapon_nodes: Array[Weapon3D] = [null, null, null, null]
@export var body_nodes: Array[BodyPart] = []
@export var booster_nodes: Array[Booster] = []
var hand_unit_r_rest := Transform3D(Vector3(1.0, 0.0, 0.0), Vector3(0.0, 1.0, 0.0), Vector3(-0.0, 0.0, 1.0), Vector3(0.167372, 0.0, 0.542358))
var hand_unit_l_rest := Transform3D(Vector3(1.0, 0.0, 0.0), Vector3(0.0, 1.0, 0.0), Vector3(-0.0, 0.0, 1.0), Vector3(-0.167372, 0.0, 0.542358))

func _ready():
	if Engine.is_editor_hint():
		return
	_build_body()
	_build_weapons()

func set_part_scene(p_data: PartData, part_type: int) -> void:
	var rebuild_body = false
	var rebuild_weapons = false
	match part_type:
		0:
			if not data.head == p_data:
				rebuild_body = true
				data.head = p_data
		1:
			if not data.arms == p_data:
				rebuild_body = true
				data.arms = p_data
		2:
			if not data.torso == p_data:
				rebuild_body = true
				data.torso = p_data
		3:
			if not data.legs == p_data:
				rebuild_body = true
				data.legs = p_data
		4:
			if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
				if not data.left_arm == p_data:
					rebuild_weapons = true
					data.left_arm = p_data
			else:
				if not data.right_arm == p_data:
					rebuild_weapons = true
					data.right_arm = p_data
		5:
			if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
				if not data.left_back == p_data:
					rebuild_weapons = true
					data.left_back = p_data
			else:
				if not data.right_back == p_data:
					rebuild_weapons = true
					data.right_back = p_data
		6:
			if not data.booster == p_data:
				rebuild_body = true
				data.booster = p_data
		7:
			if not data.generator == p_data:
				data.generator = p_data
		8:
			if not data.lock_on == p_data:
				data.lock_on = p_data
	if rebuild_weapons:
		_build_weapons.call_deferred()
	if rebuild_body:
		_build_body.call_deferred()

func _clear_body() -> void:
	for node in body_nodes:
		if node:
			node.free()
	body_nodes.clear()
	booster_nodes.clear()
	%Skeleton3D.clear_bones()
	data.max_hp = 0.0
	data.bullet_defense = 0.0
	data.energy_defense = 0.0
	data.explosive_defense = 0.0

func _clear_weapons() -> void:
	for node in weapon_nodes:
		if node:
			node.free()
	weapon_nodes.clear()
	weapon_nodes.resize(4)

func _build_body() -> void:
	if not data:
		push_warning('Missing RobotData')
		return
	if not (data.legs and data.torso and data.arms and data.head):
		push_warning('Missing Body Parts')
		return
	_clear_body()
	body_nodes.append(_setup_body_part(data.head.scene, data.head))
	body_nodes.append(_setup_body_part(data.arms.scene, data.arms))
	body_nodes.append(_setup_body_part(data.torso.scene, data.torso))
	body_nodes.append(_setup_body_part(data.legs.scene, data.legs))
	_setup_boosters()
	data.bullet_defense /= 1000.0
	data.energy_defense /= 1000.0
	data.explosive_defense /= 1000.0
	%Skeleton3D.set_bone_parent(%Skeleton3D.find_bone('Torso'), %Skeleton3D.find_bone('TorsoJoint'))
	%Skeleton3D.set_bone_parent(%Skeleton3D.find_bone('Shoulder.R'), %Skeleton3D.find_bone('ArmJoint.R'))
	%Skeleton3D.set_bone_parent(%Skeleton3D.find_bone('Shoulder.L'), %Skeleton3D.find_bone('ArmJoint.L'))
	%Skeleton3D.set_bone_rest(%Skeleton3D.add_bone('HandUnit.R'), hand_unit_r_rest)
	%Skeleton3D.set_bone_rest(%Skeleton3D.add_bone('HandUnit.L'), hand_unit_l_rest)
	%Skeleton3D.set_bone_parent(%Skeleton3D.find_bone('HandUnit.R'), %Skeleton3D.find_bone('Hand.R'))
	%Skeleton3D.set_bone_parent(%Skeleton3D.find_bone('HandUnit.L'), %Skeleton3D.find_bone('Hand.L'))
	%Skeleton3D.reset_bone_poses()
	if %AnimationTree:
		%AnimationTree.clear_caches() # hmm
	%Hands.skeleton = %Hands.get_path_to(%Skeleton3D)
	%MeleeUnit.bone_idx = %Skeleton3D.find_bone('MeleeUnit')
	%HandUnitR.bone_idx = %Skeleton3D.find_bone('HandUnit.R')
	%HandUnitL.bone_idx = %Skeleton3D.find_bone('HandUnit.L')
	%BackUnitR.bone_idx = %Skeleton3D.find_bone('BackUnit.R')
	%BackUnitL.bone_idx = %Skeleton3D.find_bone('BackUnit.L')
	%Torso.bone_idx = %Skeleton3D.find_bone('Torso')
	%LookAtLegBase.bone = %Skeleton3D.find_bone('LegBase')
	%LookAtTorso.bone = %Torso.bone_idx
	%LookAtArmR.shoulder_bone = %Skeleton3D.find_bone('Shoulder.R')
	%LookAtArmR.arm_bone = %Skeleton3D.find_bone('Forearm.R')
	%LookAtArmL.shoulder_bone = %Skeleton3D.find_bone('Shoulder.L')
	%LookAtArmL.arm_bone = %Skeleton3D.find_bone('Forearm.L')
	if make_owner:
		var parent = get_parent()
		for node in body_nodes:
			node.owner = parent
	body_built.emit.call_deferred(body_nodes + booster_nodes)

func _build_weapons() -> void:
	_clear_weapons()
	if not data:
		push_warning('Missing RobotData')
		return
	if data.right_arm:
		weapon_nodes.set(0, data.right_arm.scene.instantiate())
		%HandUnitR.add_child(weapon_nodes[0])
	if data.left_arm:
		weapon_nodes.set(1, data.left_arm.scene.instantiate())
		if weapon_nodes[1] is MeleeWeapon:
			%MeleeUnit.add_child(weapon_nodes[1])
		else:
			%HandUnitL.add_child(weapon_nodes[1])
		weapon_nodes[1].left_side = true
	if data.right_back:
		weapon_nodes.set(2, data.right_back.scene.instantiate())
		%BackUnitR.add_child(weapon_nodes[2])
	if data.left_back:
		weapon_nodes.set(3, data.left_back.scene.instantiate())
		%BackUnitL.add_child(weapon_nodes[3])
		weapon_nodes[3].left_side = true
	if make_owner:
		for node in weapon_nodes:
			node.owner = get_parent()
	weapons_built.emit.call_deferred(weapon_nodes)

func _setup_body_part(scene: PackedScene, p_data: BodyPartData) -> BodyPart:
	var new_part = scene.instantiate()
	data.max_hp += p_data.armor
	data.bullet_defense += p_data.bullet_defense
	data.energy_defense += p_data.energy_defense
	data.explosive_defense += p_data.explosive_defense
	if not p_data is HeadData:
		_setup_skeleton(%Skeleton3D, p_data.bone_list)
	%Skeleton3D.add_child(new_part)
	new_part.skeleton = new_part.get_path_to(%Skeleton3D)
	return new_part

func _setup_skeleton(skeleton: Skeleton3D, bone_list: Dictionary) -> void:
	for bone: String in bone_list.keys():
		var bone_id = skeleton.add_bone(bone)
		skeleton.set_bone_rest(bone_id, bone_list[bone][0]) 
	for parent: String in bone_list.keys():
		var parent_id = skeleton.find_bone(parent)
		for child: String in bone_list[parent][1]:
			var child_id = skeleton.find_bone(child)
			skeleton.set_bone_parent(child_id, parent_id)

func _setup_boosters() -> void:
	for part in body_nodes:
		_setup_boost_attachments(part)

func _setup_boost_attachments(body_part: BodyPart) -> void:
	var tank_leg = data.legs.leg_type == LegsData.Type.TANK
	for child in body_part.get_children():
		if not child.name.containsn('Booster'):
			continue
		if child is BoneAttachment3D:
			child.use_external_skeleton = true
			child.external_skeleton = child.get_path_to(%Skeleton3D)
			child.bone_idx = %Skeleton3D.find_bone(child.name)
			if child.name.containsn('TorsoBooster'):
				if tank_leg:
					child.free()
				else:
					var new_booster = data.booster.scene.instantiate()
					child.add_child(new_booster)
					new_booster.rotation.x = PI
					booster_nodes.append(new_booster)
			else:
				child.get_child(0).rotation.x = PI
				booster_nodes.append(child.get_child(0))
