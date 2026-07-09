@tool
extends Node

@export_tool_button('MakeData') var button1 = make_data
@export_enum('Leg', 'Torso', 'Arms', 'Head') var type := 'Leg'
@export var skeleton: Skeleton3D = null
@export var mesh_inst: MeshInstance3D = null
var regex: RegEx = RegEx.create_from_string('^(Torso)$|^(Shoulder)')

func make_data():
	var path = 'res://parts/test/'
	match type:
		'Leg':
			mesh_inst.data = LegsPartData.new()
		'Torso':
			mesh_inst.data = TorsoPartData.new()
		'Arms':
			mesh_inst.data = ArmsPartData.new()
		'Head':
			mesh_inst.data = HeadPartData.new()
	for bone: int in skeleton.get_parentless_bones():
		iterate_skeleton(bone, mesh_inst.data, mesh_inst.skin)
	var data = mesh_inst.data
	ResourceSaver.save(data, path)

func iterate_skeleton(bone_id: int, data: BodyPartData, skin: Skin):
	var bone_name = skeleton.get_bone_name(bone_id)
	var pose = skeleton.get_bone_rest(bone_id)
	var children = skeleton.get_bone_children(bone_id)
	var children_names = []
	for child: int in children:
		children_names.append(skeleton.get_bone_name(child))
	if regex.search(bone_name):
		pose = pose.rotated(Vector3.UP, PI)
		#for bind in range(skin.get_bind_count()):
		#	if skin.get_bind_name(bind) == bone_name:
		#		skin.set_bind_pose(bind, skin.get_bind_pose(bind).rotated(Vector3.UP, PI))
		#		break
		#print('bone z flipped: ', bone_name)
	data.bone_list.get_or_add(bone_name, [pose, children_names])
	for bone: int in children:
		iterate_skeleton(bone, data, skin)
