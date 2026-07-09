@tool
extends Node

signal body_built(nodes: Array[BodyPart])
signal weapons_built(nodes: Array[Weapon])

@export_tool_button('BUILD BODY', 'BuildCSharp') var build1 = _build_body
@export_tool_button('BUILD WEAPONS', 'BuildCSharp') var build2 = _build_weapons
@export var make_owner := false
@export var data: PlayerRobotData = null
@export var body_nodes: Array[Node] = []
@export var weapon_nodes: Array[Node] = []

func _ready():
	if Engine.is_editor_hint():
		return
	_build_body()
	_build_weapons()

func clear_body():
	for node in body_nodes:
		if node:
			node.free()
	body_nodes.clear()
	%Skeleton3D.clear_bones()
	data.max_hp = 0.0
	data.defense_bullet = 0.0
	data.defense_energy = 0.0
	data.defense_explosive = 0.0

func clear_weapons():
	for node in weapon_nodes:
		if node:
			node.free()
	weapon_nodes.clear()

func set_part_scene(scene: PackedScene, part_type: int):
	var rebuild_body = false
	var rebuild_weapons = false
	match part_type:
		1:
			if not data.head_part == scene:
				rebuild_body = true
				data.head_part = scene
		2:
			if not data.arms_part == scene:
				rebuild_body = true
				data.arms_part = scene
		3:
			if not data.torso_part == scene:
				rebuild_body = true
				data.torso_part = scene
		4:
			if not data.legs_part == scene:
				rebuild_body = true
				data.legs_part = scene
		5:
			if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
				if not data.left_arm_part == scene:
					rebuild_weapons = true
					data.left_arm_part = scene
			else:
				if not data.right_arm_part == scene:
					rebuild_weapons = true
					data.right_arm_part = scene
		6:
			if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
				if not data.left_back_part == scene:
					rebuild_weapons = true
					data.left_back_part = scene
			else:
				if not data.right_back_part == scene:
					rebuild_weapons = true
					data.right_back_part = scene
	if rebuild_weapons:
		_build_weapons.call_deferred()
	if rebuild_body:
		_build_body.call_deferred()

func _build_body():
	clear_body()
	body_nodes.append(_setup_body_part(data.legs_part))
	body_nodes.append(_setup_body_part(data.torso_part))
	body_nodes.append(_setup_body_part(data.arms_part))
	body_nodes.append(_setup_body_part(data.head_part))
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
	%Hands.skeleton = %Skeleton3D.get_path()
	%ArmUnitR.bone_idx = %Skeleton3D.find_bone('ArmUnit.R')
	%ArmUnitL.bone_idx = %Skeleton3D.find_bone('ArmUnit.L')
	%BackUnitR.bone_idx = %Skeleton3D.find_bone('BackUnit.R')
	%BackUnitL.bone_idx = %Skeleton3D.find_bone('BackUnit.L')
	%Torso.bone_idx = %Skeleton3D.find_bone('Torso')
	%LookAtTorso.bone = %Torso.bone_idx
	%LookAtArmJointR.bone = %Skeleton3D.find_bone('ArmJoint.R')
	%LookAtArmJointL.bone = %Skeleton3D.find_bone('ArmJoint.L')
	%LookAtArmR.bone = %Skeleton3D.find_bone('Forearm.R')
	%LookAtArmL.bone = %Skeleton3D.find_bone('Forearm.L')
	if make_owner:
		for node in body_nodes:
			node.owner = get_parent()
	body_built.emit(body_nodes)

func _build_weapons():
	clear_weapons()
	#var node_path = get_parent().get_path() if get_parent() is Character else ^''
	if data.right_arm_part:
		weapon_nodes.append(data.right_arm_part.instantiate())
		%ArmUnitR.add_child(weapon_nodes.back())
		#weapon_nodes.back().data.damage_data.source = node_path
	if data.left_arm_part:
		weapon_nodes.append(data.left_arm_part.instantiate())
		%ArmUnitL.add_child(weapon_nodes.back())
		weapon_nodes.back().left_side = true
		#weapon_nodes.back().data.damage_data.source = node_path
	if data.right_back_part:
		weapon_nodes.append(data.right_back_part.instantiate())
		%BackUnitR.add_child(weapon_nodes.back())
		#weapon_nodes.back().data.damage_data.source = node_path
	if data.left_back_part:
		weapon_nodes.append(data.left_back_part.instantiate())
		%BackUnitL.add_child(weapon_nodes.back())
		weapon_nodes.back().left_side = true
		#weapon_nodes.back().data.damage_data.source = node_path
	if make_owner:
		for node in weapon_nodes:
			node.owner = get_parent()
	weapons_built.emit(weapon_nodes)

func _setup_body_part(scene: PackedScene) -> Node:
	var part = scene.instantiate()
	data.max_hp += part.data.armor
	data.defense_bullet += part.data.defense_bullet
	data.defense_energy += part.data.defense_energy
	data.defense_explosive += part.data.defense_explosive
	if not scene == data.head_part:
		_setup_skeleton(%Skeleton3D, part.data.bone_list)
	%Skeleton3D.add_child(part)
	part.skeleton = %Skeleton3D.get_path()
	return part

func _setup_skeleton(skeleton: Skeleton3D, bone_list: Dictionary):
	for bone: String in bone_list.keys():
		var bone_id = skeleton.add_bone(bone)
		skeleton.set_bone_rest(bone_id, bone_list[bone][0]) 
	for parent: String in bone_list.keys():
		var parent_id = skeleton.find_bone(parent)
		for child: String in bone_list[parent][1]:
			var child_id = skeleton.find_bone(child)
			skeleton.set_bone_parent(child_id, parent_id)
