@tool
extends Node3D

@export_tool_button('Generate', 'BuildCSharp') var button1 = create_miniatures
@export_dir var save_path := 'res://ui/part_preview/'
@export_dir var parts_path := 'res://parts/test/'
@export var viewport: SubViewport = null
@export var camera: Camera3D = null

func _ready():
	viewport = find_child('SubViewport')
	camera = find_child('Camera3D')

func create_miniatures():
	if not (Engine.is_editor_hint() and viewport and camera):
		return
	for file in ResourceLoader.list_directory(parts_path):
		if not file.ends_with('_data.tres'):
			continue
		var data_path = parts_path + file
		var part_data: PartData = ResourceLoader.load(data_path)
		var part = part_data.scene.instantiate()
		
		viewport.add_child(part)
		
		var aabb: AABB = find_aabb(part)
		var large_side = aabb.size.x if aabb.size.x > aabb.size.z else aabb.size.z
		var corner = Vector3(large_side, aabb.size.y / 2.0, -large_side)
		
		camera.position = aabb.get_center() + corner
		camera.look_at(aabb.get_center())
		
		await RenderingServer.frame_post_draw
		part.free()
		
		var preview_path = save_path + file.get_slice('.', 0) + '_preview.png'
		var error = viewport.get_texture().get_image().save_png(preview_path)
		if error:
			push_warning(error_string(error), ' ', preview_path)
			continue
		
		part_data.preview = ResourceLoader.load(preview_path)
		error = ResourceSaver.save(part_data, data_path)
		if error:
			push_warning(error_string(error), ' ', data_path)

func find_aabb(node: Node) -> AABB:
	if node is VisualInstance3D:
		return node.get_aabb()
	return iterate(node).get_aabb()

func iterate(node: Node) -> VisualInstance3D:
	for child in node.get_children():
		if child is VisualInstance3D:
			return child
		if child.get_child_count():
			return iterate(child)
	return null
