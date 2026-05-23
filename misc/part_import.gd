@tool
extends EditorScenePostImport

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
		var scene := PackedScene.new()
		var path = 'res://copyright_shit/' + part_id + '.tscn'
		scene.pack(body_part)
		var err = ResourceSaver.save(scene, path)
		if not err == OK:
			push_warning(part_id, node.name, 'not saved,', err)
	for child in node.get_children():
		iterate(child)
