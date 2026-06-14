@tool
extends Node

@export_tool_button('BUILD', 'BuildCSharp') var build = build_body
@export var data: PlayerRobotData = null
@export var parts: Array[Node] = []

func clear():
	for node in parts:
		if node:
			node.free()
	parts.clear()
	%Skeleton3D.clear_bones()

func build_body():
	clear()
	parts.append(setup_body_part(data.legs_part))
	parts.append(setup_body_part(data.torso_part))
	parts.append(setup_body_part(data.arms_part))
	parts.append(setup_body_part(data.head_part))
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
	%LookAtArmJointR.bone = %Skeleton3D.find_bone('ArmJoint.R')
	%LookAtArmJointL.bone = %Skeleton3D.find_bone('ArmJoint.L')
	%LookAtArmR.bone = %Skeleton3D.find_bone('Forearm.R')
	%LookAtArmL.bone = %Skeleton3D.find_bone('Forearm.L')
	if data.right_arm_part:
		var right_arm_unit = data.right_arm_part.instantiate()
		%ArmUnitR.add_child(right_arm_unit)
		parts.append(right_arm_unit)
	if data.left_arm_part:
		var left_arm_unit = data.left_arm_part.instantiate()
		%ArmUnitL.add_child(left_arm_unit)
		left_arm_unit.left_side = true
		left_arm_unit.scale.x = -1.0
		parts.append(left_arm_unit)
	if data.right_back_part:
		var right_back_unit = data.right_back_part.instantiate()
		%BackUnitR.add_child(right_back_unit)
		parts.append(right_back_unit)
	if data.left_back_part:
		var left_back_unit = data.left_back_part.instantiate()
		%BackUnitL.add_child(left_back_unit)
		left_back_unit.left_side = true
		left_back_unit.scale.x = -1.0
		parts.append(left_back_unit)
	for part in parts:
		part.owner = owner

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

func setup_skeleton(skeleton: Skeleton3D, bone_list: Dictionary):
	for bone: String in bone_list.keys():
		var bone_id = skeleton.add_bone(bone)
		skeleton.set_bone_rest(bone_id, bone_list[bone][0]) 
	for parent: String in bone_list.keys():
		var parent_id = skeleton.find_bone(parent)
		for child: String in bone_list[parent][1]:
			var child_id = skeleton.find_bone(child)
			skeleton.set_bone_parent(child_id, parent_id)
