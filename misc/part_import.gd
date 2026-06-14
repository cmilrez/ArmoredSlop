@tool
extends EditorScenePostImport

var regex: RegEx = RegEx.create_from_string('^(Torso)$|^(Shoulder)')

func _post_import(scene: Node):
	iterate(scene)
	return scene

func iterate(node: Node):
	if node == null:
		return
	if node is MeshInstance3D:
		var body_part := BodyPart.new()
		body_part.name = node.name
		body_part.mesh = node.mesh
		body_part.skin = node.skin
		var part_id = node.get_parent().get_parent().name
		match part_id.erase(0, 2).left(1):
			'1':
				body_part.data = HeadPartData.new()
			'2':
				body_part.data = ArmsPartData.new()
			'3':
				body_part.data = TorsoPartData.new()
			'4':
				body_part.data = LegsPartData.new()
		var skeleton: Skeleton3D = node.get_parent()
		for bone: int in skeleton.get_parentless_bones():
			iterate_skeleton(skeleton, bone, body_part.data, body_part.skin)
		var scene := PackedScene.new()
		var path = 'res://copyright_shit/'
		scene.pack(body_part)
		var error1 = ResourceSaver.save(scene, path + part_id + '.tscn')
		if error1:
			push_warning(part_id, ' ', node.name, ' not saved, ', error1)
		else:
			var index = PartIndex.new()
			index.scene = ResourceLoader.load(path + part_id + '.tscn')
			index.data = body_part.data
			index.ui_miniature = ResourceLoader.load(path + 'miniatures/' + part_id + '.png')
			var error2 = ResourceSaver.save(index, path + part_id + '_ID.tres')
			if error2:
				push_warning(part_id, ' index not saved, ', error1)
	for child in node.get_children():
		iterate(child)

func iterate_skeleton(skeleton: Skeleton3D, bone_id: int, data: BodyPartData, skin: Skin):
	var name = skeleton.get_bone_name(bone_id)
	var pose = skeleton.get_bone_rest(bone_id)
	var children = skeleton.get_bone_children(bone_id)
	var children_names = []
	for child: int in children:
		children_names.append(skeleton.get_bone_name(child))
	if regex.search(name):
		pose = pose.rotated(Vector3.UP, PI)
		#for bind in range(skin.get_bind_count()):
		#	if skin.get_bind_name(bind) == name:
		#		skin.set_bind_pose(bind, skin.get_bind_pose(bind).rotated(Vector3.UP, PI))
		#		break
		print('bone z flipped: ', name)
	data.bone_list.get_or_add(name, [pose, children_names])
	for bone: int in children:
		iterate_skeleton(skeleton, bone, data, skin)
