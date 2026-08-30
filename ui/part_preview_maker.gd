@tool
extends SubViewport

@onready var camera: Camera3D = get_camera_3d()

@export_tool_button('Generate Many', 'BuildCSharp') var button1 = create_miniatures
@export_dir var save_path := 'res://ui/part_preview/':
	set(value):
		save_path = validate_path(value)
@export_dir var parts_path := 'res://parts/test/':
	set(value):
		parts_path = validate_path(value)
@export_tool_button('Test Camera', 'Camera') var button2 = test
@export var test_node: Node = null
@export_tool_button('Generate One', 'BuildCSharp') var button3 = create_one_miniature
@export var one: PartData = null

func validate_path(value: String) -> String:
	if not value.ends_with('/'):
		value += '/'
	return value

func test() -> void:
	if test_node:
		center_object_to_camera(test_node)

func create_one_miniature() -> void:
	if not (Engine.is_editor_hint() and camera):
		return
	if not one:
		return
	var part = one.scene.instantiate()
	
	add_child(part)
	center_object_to_camera(part)
	
	await RenderingServer.frame_post_draw
	part.free()
	
	var path = one.resource_path
	var preview_path = save_path + path.get_file().get_slice('.', 0).replace('data', 'preview.png')
	var error = get_texture().get_image().save_png(preview_path)
	if error:
		push_warning('OOPS: ', error_string(error), ' ', preview_path)
		return
	
	one.preview = ResourceLoader.load(preview_path)
	error = ResourceSaver.save(one, path)
	if error:
		push_warning('OOPS: ', error_string(error), ' ', path)

func create_miniatures() -> void:
	if not (Engine.is_editor_hint() and camera):
		return
	for file in ResourceLoader.list_directory(parts_path):
		if not file.ends_with('_data.tres'):
			continue
		var data_path = parts_path + file
		var part_data: PartData = ResourceLoader.load(data_path)
		var part = part_data.scene.instantiate()
		
		add_child(part)
		center_object_to_camera(part)
		
		await RenderingServer.frame_post_draw
		part.free()
		
		var preview_path = save_path + file.get_slice('.', 0).replace('data', 'preview.png')
		var error = get_texture().get_image().save_png(preview_path)
		if error:
			push_warning('OOPS: ', error_string(error), ' ', preview_path)
			continue
		
		part_data.preview = ResourceLoader.load(preview_path)
		error = ResourceSaver.save(part_data, data_path)
		if error:
			push_warning('OOPS: ', error_string(error), ' ', data_path)

func center_object_to_camera(node: Node) -> void:
	var aabb = find_aabb(node)
	var center = aabb.get_center()
	aabb.position -= center
	# Create and rotate Transform
	var xform = Transform3D()
	xform.basis = Basis().rotated(Vector3.UP, PI * 0.125)
	if node is BodyPart:
		xform.basis = Basis().rotated(Vector3.UP, PI) * xform.basis
	xform.basis = Basis().rotated(Vector3.RIGHT, PI * 0.125) * xform.basis;
	var rot_aabb = xform * aabb
	# Scale Transform to fill the camera frustum
	var m = max(rot_aabb.size.x, rot_aabb.size.y) * 0.5
	m = 1.0 / m
	m *= 0.5
	xform.basis = xform.basis.scaled(Vector3(m, m, m))
	# Center Transform
	xform.origin = -(xform.basis * center)
	xform.origin.z -= rot_aabb.size.z * 2.0
	# Apply Transform
	node.global_transform = xform

func find_aabb(node: Node) -> AABB:
	var aabb = AABB()
	if node is MeshInstance3D:
		if node.visible:
			var parent = node.get_parent()
			if parent is Node3D:
				if parent.visible:
					aabb = node.transform * node.get_aabb()
			else:
				aabb = node.transform * node.get_aabb()
	for child in node.get_children():
		var child_aabb = find_aabb(child)
		aabb = aabb.merge(child_aabb)
	return aabb
