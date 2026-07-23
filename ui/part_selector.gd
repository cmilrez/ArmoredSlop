@tool
extends Control

signal part_selected(part: PackedScene, part_type: int)

@onready var tabs = $TabContainer

@export_tool_button('Build UI', 'BuildCSharp') var button1 = build_ui
@export_tool_button('Fetch Parts', 'Zoom') var button2 = fetch_parts
@export var parts: Array[Array] = [[], [], [], [], [], [], []]

func _ready():
	if Engine.is_editor_hint():
		return
	tabs.hide()

func _input(event):
	if event.is_action_pressed('show_part_select'):
		tabs.visible = not tabs.visible
		if tabs.visible:
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		else:
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func clear():
	for tab in tabs.get_children():
		for child in tab.get_children():
			child.free()

func get_part_scene(id: String):
	if tabs.visible:
		var part_type = int(id.left(1))
		part_selected.emit(parts[part_type][int(id.erase(0))], part_type + 1)

func build_ui():
	#clear()
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
			new_button.pressed.connect(get_part_scene.bind(new_button.name))
			new_button.show()

func fetch_parts():
	var path := &'res://parts/test/'
	for file in ResourceLoader.list_directory(path):
		if not file.ends_with('_data.tres'):
			continue
		var data = ResourceLoader.load(path + file)
		var i = -1
		if data is HeadData:
			i = 0
		elif data is ArmsData:
			i = 1
		elif data is TorsoData:
			i = 2
		elif data is LegsData:
			i = 3
		elif data is BoosterData:
			i = 6
		if i < 0:
			continue
		parts[i].append(data)
