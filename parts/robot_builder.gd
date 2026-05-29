@tool
extends Node

@export_tool_button('Build') var build = setup_parts
@export var data: PlayerRobotData = null
@export var parts: Array[Node] = []

func clear():
	for node: Node in parts:
		if node:
			node.free()
	parts.clear()

func setup_parts():
	clear()
	if not (data.legs_part and data.torso_part and data.arms_part and data.head_part):
		return
	var legs = data.legs_part.instantiate()
	var torso = data.torso_part.instantiate()
	var arms = data.arms_part.instantiate()
	var head = data.head_part.instantiate()
	
	data.max_hp = legs.data.defense_bullet + torso.data.armor + arms.data.armor + head.data.armor
	data.defense_bullet = (legs.data.defense_bullet + torso.data.defense_bullet + arms.data.defense_bullet + head.data.defense_bullet) / 1000.0
	data.defense_energy = (legs.data.defense_energy + torso.data.defense_energy + arms.data.defense_energy + head.data.defense_energy) / 1000.0
	data.defense_explosive = (legs.data.defense_explosive + torso.data.defense_explosive + arms.data.defense_explosive + head.data.defense_explosive) / 1000.0
	
	%Skeleton3D.clear_bones()
	setup_skeleton(%Skeleton3D, legs.data.bone_list)
	setup_skeleton(%Skeleton3D, torso.data.bone_list)
	setup_skeleton(%Skeleton3D, arms.data.bone_list)
	%Skeleton3D.set_bone_parent(%Skeleton3D.find_bone('Torso'), %Skeleton3D.find_bone('TorsoJoint'))
	%Skeleton3D.set_bone_parent(%Skeleton3D.find_bone('Shoulder.R'), %Skeleton3D.find_bone('ArmJoint.R'))
	%Skeleton3D.set_bone_parent(%Skeleton3D.find_bone('Shoulder.L'), %Skeleton3D.find_bone('ArmJoint.L'))
	%Skeleton3D.set_bone_rest(%Skeleton3D.add_bone('ArmUnit.R'), %HandSkel.get_bone_rest(%HandSkel.find_bone('ArmUnit.R')))
	%Skeleton3D.set_bone_rest(%Skeleton3D.add_bone('ArmUnit.L'), %HandSkel.get_bone_rest(%HandSkel.find_bone('ArmUnit.L')))
	%Skeleton3D.set_bone_parent(%Skeleton3D.find_bone('ArmUnit.R'), %Skeleton3D.find_bone('Hand.R'))
	%Skeleton3D.set_bone_parent(%Skeleton3D.find_bone('ArmUnit.L'), %Skeleton3D.find_bone('Hand.L'))
	#setup_skeleton(%Skeleton3D, head.data.bone_list)
	%Skeleton3D.reset_bone_poses()
	
	%Skeleton3D.add_child(legs)
	%Skeleton3D.add_child(torso)
	%Skeleton3D.add_child(arms)
	%Skeleton3D.add_child(head)
	legs.skeleton = %Skeleton3D.get_path()
	torso.skeleton = %Skeleton3D.get_path()
	arms.skeleton = %Skeleton3D.get_path()
	head.skeleton = %Skeleton3D.get_path()
	%Hands.skeleton = %Skeleton3D.get_path()
	parts.append(legs)
	parts.append(torso)
	parts.append(arms)
	parts.append(head)
	
	var node_path = owner.get_path()
	%ArmUnitR.bone_idx = %Skeleton3D.find_bone('ArmUnit.R')
	if data.right_arm_part:
		var right_arm_unit = data.right_arm_part.instantiate()
		%ArmUnitR.add_child(right_arm_unit)
		parts.append(right_arm_unit)
		right_arm_unit.data.damage_data.source = node_path
		#right_arm_unit.ammo_changed.connect(robot_hud.update_ammo_display.bind(0))
	%ArmUnitL.bone_idx = %Skeleton3D.find_bone('ArmUnit.L')
	if data.left_arm_part:
		var left_arm_unit = data.left_arm_part.instantiate()
		%ArmUnitL.add_child(left_arm_unit)
		parts.append(left_arm_unit)
		left_arm_unit.data.damage_data.source = node_path
		#left_arm_unit.ammo_changed.connect(robot_hud.update_ammo_display.bind(1))
	%BackUnitR.bone_idx = %Skeleton3D.find_bone('BackUnit.R')
	if data.right_back_part:
		var right_back_unit = data.right_back_part.instantiate()
		%BackUnitR.add_child(right_back_unit)
		parts.append(right_back_unit)
		right_back_unit.data.damage_data.source = node_path
		#right_back_unit.ammo_changed.connect(robot_hud.update_ammo_display.bind(2))
	%BackUnitL.bone_idx = %Skeleton3D.find_bone('BackUnit.L')
	if data.left_back_part:
		var left_back_unit = data.left_back_part.instantiate()
		%BackUnitL.add_child(left_back_unit)
		parts.append(left_back_unit)
		left_back_unit.data.damage_data.source = node_path
		#left_back_unit.ammo_changed.connect(robot_hud.update_ammo_display.bind(3))
	for part in parts:
		part.owner = owner

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
