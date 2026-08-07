@tool
extends EditorScenePostImport

var regex: RegEx = RegEx.create_from_string('^(Torso)$|^(Shoulder)')
var path := &'res://parts/test/'

func _post_import(scene: Node):
	iterate(scene)
	return scene

func iterate(node: Node) -> void:
	if node == null:
		return
	if node is MeshInstance3D:
		var name = node.name.to_snake_case()
		var scene_path = path + name + '.tscn'
		var data_path = path + name + '_data.tres'
		var part_scene = load_part_scene(scene_path)
		var part_data = load_part_data(data_path, int(node.get_parent().get_parent().name.trim_prefix('BP').left(1)))
		var new_part = MeshInstance3D.new()
		if part_scene:
			new_part = part_scene.instantiate()
		else:
			part_scene = PackedScene.new()
			if part_data is BodyPartData:
				new_part = BodyPart.new()
		new_part.name = node.name
		new_part.mesh = node.mesh
		new_part.skin = node.skin
		var skeleton = node.get_parent()
		if skeleton is Skeleton3D:
			for bone in skeleton.get_parentless_bones():
				iterate_skeleton(skeleton, bone, part_data)
		var error = part_scene.pack(new_part)
		if error:
			push_warning('OOPS: ',  error_string(error), ' ', new_part.name)
		error = ResourceSaver.save(part_scene, scene_path)
		if error:
			push_warning('OOPS: ',  error_string(error), ' ', scene_path)
		part_data.scene = part_scene
		error = ResourceSaver.save(part_data, data_path)
		if error:
			push_warning('OOPS: ',  error_string(error), ' ', data_path)
	for child in node.get_children():
		iterate(child)

func load_part_scene(scene_path: StringName) -> PackedScene:
	if ResourceLoader.exists(scene_path):
		return ResourceLoader.load(scene_path)
	return null

func load_part_data(data_path: StringName, part_type: int) -> PartData:
	var data: PartData = null
	if ResourceLoader.exists(data_path):
		data = ResourceLoader.load(data_path)
		if data is BodyPartData:
			data.bone_list.clear()
	else:
		match part_type:
			1:
				data = HeadData.new()
			2:
				data = ArmsData.new()
			3:
				data = TorsoData.new()
			4:
				data = LegsData.new()
	return data

func iterate_skeleton(skeleton: Skeleton3D, bone_id: int, data: BodyPartData) -> void:
	var name = StringName(skeleton.get_bone_name(bone_id))
	var pose = skeleton.get_bone_rest(bone_id)
	var children = skeleton.get_bone_children(bone_id)
	var children_names = []
	for child: int in children:
		children_names.append(StringName(skeleton.get_bone_name(child)))
	if regex.search(name):
		pose = pose.rotated(Vector3.UP, PI)
	data.bone_list.get_or_add(name, [pose, children_names])
	for bone: int in children:
		iterate_skeleton(skeleton, bone, data)
