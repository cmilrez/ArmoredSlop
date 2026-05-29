@tool
extends Control

signal part_selected(part: PackedScene, part_type: int)

@onready var head_parts = $Rows/HeadParts
@onready var arm_parts = $Rows/ArmParts
@onready var torso_parts = $Rows/TorsoParts
@onready var leg_parts = $Rows/LegParts
@onready var rows = $Rows

@export_tool_button('GenMiniatures') var button1 = create_miniatures
@export var sub_viewport: SubViewport = null
@export_dir var parts_path := '':
	set(value):
		if value and not value.ends_with('/'):
			value += '/'
		parts_path = value
@export_tool_button('BuildUI') var button2 = build_ui
@export var parts: Array[Array] = [[], [], [], []]

func _ready():
	if Engine.is_editor_hint():
		return
	rows.hide()

func _input(event):
	if event.is_action_pressed('show_part_select'):
		rows.visible = not rows.visible
		if rows.visible:
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		else:
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func clear():
	for child: Node in head_parts.get_children():
		child.free()
	for child: Node in arm_parts.get_children():
		child.free()
	for child: Node in torso_parts.get_children():
		child.free()
	for child: Node in leg_parts.get_children():
		child.free()

func get_part_scene(id: String):
	if rows.visible:
		var part_type = int(id.left(1))
		part_selected.emit(parts[part_type][int(id.erase(0))], part_type + 1)

func build_ui():
	#parts = [[], [], [], []]
	#clear()
	var names := ResourceLoader.list_directory(parts_path)
	for file_name in names:
		if not (file_name.ends_with('.tscn') or file_name.ends_with('.scn')):
			continue
		var part_scene = ResourceLoader.load(parts_path + file_name)
		var part = part_scene.instantiate()
		if not part is MeshInstance3D:
			continue
		var tex_button = TextureButton.new()
		tex_button.texture_normal = part.data.ui_miniature
		tex_button.ignore_texture_size = true
		tex_button.stretch_mode = TextureButton.STRETCH_SCALE
		tex_button.custom_minimum_size = Vector2.ONE * 100.0
		tex_button.mouse_filter = Control.MOUSE_FILTER_PASS
		part.free()
		match file_name.erase(0, 2).left(1):
			'1':
				head_parts.add_child(tex_button)
				parts[0].append(part_scene)
				tex_button.name = '0' + str(parts[0].size() - 1)
			'2':
				arm_parts.add_child(tex_button)
				parts[1].append(part_scene)
				tex_button.name = '1' + str(parts[1].size() - 1)
			'3':
				torso_parts.add_child(tex_button)
				parts[2].append(part_scene)
				tex_button.name = '2' + str(parts[2].size() - 1)
			'4':
				leg_parts.add_child(tex_button)
				parts[3].append(part_scene)
				tex_button.name = '3' + str(parts[3].size() - 1)
		tex_button.owner = self
		tex_button.pressed.connect(get_part_scene.bind(tex_button.name), Object.CONNECT_PERSIST)

var save_path := &'res://copyright_shit/miniatures/'
func create_miniatures():
	if not (Engine.is_editor_hint() and sub_viewport):
		return
	var names := ResourceLoader.list_directory(parts_path)
	for file_name in names:
		if not (file_name.ends_with('.tscn') or file_name.ends_with('.scn')):
			print(file_name, ' not a scene')
			continue
		var mesh = ResourceLoader.load(parts_path + file_name).instantiate()
		if not mesh is MeshInstance3D:
			print(file_name, ' not a mesh instance')
			mesh.free()
			continue
		sub_viewport.add_child(mesh)
		var aabb: AABB = mesh.get_aabb()
		var large_side = aabb.size.x if aabb.size.x > aabb.size.z else aabb.size.z
		#large_side /= 2.0
		var corner = Vector3(large_side, aabb.size.y / 2.0, -large_side)
		%Camera3D.position = aabb.get_center() + corner
		%Camera3D.look_at(aabb.get_center())
		await RenderingServer.frame_post_draw
		var img_name = file_name.get_slice('.', 0) + '.png'
		var error = sub_viewport.get_texture().get_image().save_png(save_path + img_name)
		if error:
			print(img_name, ' not saved error: ', error)
			continue
		print(img_name, ' saved to ', save_path)
		mesh.data.ui_miniature = ResourceLoader.load(save_path + img_name)
		var scene = PackedScene.new()
		scene.pack(mesh)
		ResourceSaver.save(scene, 'res://copyright_shit/' + file_name)
		mesh.free()
