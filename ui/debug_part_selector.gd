@tool
extends Control

signal part_selected(part_data: PartData, part_type: int)

@onready var tabs = $TabContainer

@export_tool_button('Build UI', 'BuildCSharp') var button1 = build_ui
@export_tool_button('Fetch Parts', 'Zoom') var button2 = fetch_parts
@export var parts: Array[Array] = [[], [], [], [], [], [], [], [], []]

func _ready():
	if Engine.is_editor_hint():
		return
	tabs.hide()

func _input(event):
	if event.is_action_pressed(&'debug_show_part_select'):
		tabs.visible = not tabs.visible
		if tabs.visible:
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		else:
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func clear_nodes() -> void:
	for tab in tabs.get_children():
		var children = tab.get_children()
		if children.get(0).name.length() == 1:
			children.pop_front()
		for child in children:
			child.free()

func get_part_scene(id: String) -> void:
	if tabs.visible:
		var part_type = int(id.left(1))
		if id.length() > 1:
			var part_number = int(id.erase(0))
			part_selected.emit(parts[part_type][part_number], part_type)
		else:
			part_selected.emit(null, part_type)

func build_ui() -> void:
	clear_nodes()
	var base_button: TextureButton = $BaseButton
	for i in range(parts.size()):
		for j in range(parts[i].size()):
			var data: PartData = parts[i][j]
			var new_button = base_button.duplicate()
			var tab = tabs.get_child(i)
			tab.add_child(new_button)
			new_button.owner = self
			new_button.name = str(i) + str(j)
			new_button.texture_normal = data.preview
			new_button.pressed.connect(get_part_scene.bind(new_button.name), CONNECT_PERSIST)
			new_button.show()
			if i in [4, 5]:
				new_button.button_mask = MOUSE_BUTTON_MASK_LEFT | MOUSE_BUTTON_MASK_RIGHT

func fetch_parts() -> void:
	const PATH = &'res://parts/test/'
	for file in ResourceLoader.list_directory(PATH):
		if not file.ends_with('_data.tres'):
			continue
		var data = ResourceLoader.load(PATH + file)
		var i = -1
		if   data is HeadData:      i = 0
		elif data is ArmsData:      i = 1
		elif data is TorsoData:     i = 2
		elif data is LegsData:      i = 3
		elif data is BoosterData:   i = 6
		elif data is GeneratorData: i = 7
		elif data is LockOnData:    i = 8
		if i < 0:
			continue
		if parts[i].has(data):
			continue
		parts[i].append(data)
